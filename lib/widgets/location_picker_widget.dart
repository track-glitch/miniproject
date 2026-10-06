import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class LocationPickerWidget extends StatefulWidget {
  final LatLng initialLocation;
  final String initialAddress;
  final Function(LatLng, String) onLocationChanged;

  // 🌟 เพิ่ม Parameter สำหรับปิด-เปิดการแสดงผลช่องรายละเอียดที่อยู่
  final bool showAddressTextField;

  const LocationPickerWidget({
    super.key,
    required this.initialLocation,
    required this.initialAddress,
    required this.onLocationChanged,
    this.showAddressTextField =
        true, // 🌟 ตั้งค่าเริ่มต้นเป็น true เพื่อไม่กระทบหน้าอื่นที่ใช้อยู่
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late MapController mapController;
  late LatLng currentLocation;
  Timer? _debounce;
  final TextEditingController _addressController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  // 🌟 1. API Key ของ Longdo สำหรับระบบค้นหา (SmartSearch) และดึงที่อยู่ภาษาไทย
  final String longdoApiKey = '3f1eabefb61f80a37abf70743fe9fc33';

  // 🌟 2. API Key ของ MapTiler สำหรับดึงรูปภาพแผนที่
  final String maptilerApiKey = 'JCT1H6ehzlMaKZyrC5mp';

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    currentLocation = widget.initialLocation;
    addressController.text = widget.initialAddress;
    _addressController.text = widget.initialAddress;
  }

  @override
  void didUpdateWidget(covariant LocationPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAddress != oldWidget.initialAddress &&
        widget.initialAddress.isNotEmpty) {
      _addressController.text = widget.initialAddress;
    }
  }

  // หาตำแหน่งปัจจุบันและปักหมุด
  Future<void> _jumpToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    LatLng newPos = LatLng(position.latitude, position.longitude);

    setState(() => currentLocation = newPos);
    mapController.move(newPos, 16.5);
    _getAddressFromLongdo(newPos);
  }

  // เลื่อนหมุดเมื่อเลือกสถานที่จากระบบค้นหา
  void _selectSearchResult(double lat, double lon) {
    LatLng newPos = LatLng(lat, lon);
    setState(() {
      currentLocation = newPos;
    });
    mapController.move(newPos, 16.5);
    _getAddressFromLongdo(newPos);
  }

  // ฟังก์ชันแปลงพิกัดเป็นที่อยู่ภาษาไทย
  Future<void> _getAddressFromLongdo(LatLng location) async {
    final url = Uri.parse(
      'https://api.longdo.com/map/services/address?lat=${location.latitude}&lon=${location.longitude}&format=json&key=$longdoApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['subdistrict'] != null || data['district'] != null) {
          String fullAddress =
              '${data['subdistrict'] ?? ''} ${data['district'] ?? ''} ${data['province'] ?? ''} ${data['postcode'] ?? ''}'
                  .trim();

          setState(() {
            addressController.text = fullAddress;
          });
          widget.onLocationChanged(currentLocation, addressController.text);
        }
      }
    } catch (e) {
      print("Longdo Reverse Geocode Error: $e");
    }
  }

  // เปิดแผนที่ขยายเต็มจอ (UX แบบ Grab / Lineman)
  void _openFullScreenMap() {
    showDialog(
      context: context,
      builder: (context) {
        LatLng tempLocation = currentLocation;
        MapController dialogMapController = MapController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: dialogMapController,
                        options: MapOptions(
                          initialCenter: tempLocation,
                          initialZoom: 16.5,
                          // 🌟 อัปเดตพิกัดตลอดเวลาที่ผู้ใช้เลื่อนแผนที่
                          onPositionChanged: (position, hasGesture) {
                            if (position.center != null) {
                              tempLocation = position.center!;
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$maptilerApiKey',
                            userAgentPackageName: 'com.example.caretakerapp',
                          ),
                          // 🌟 ลบ MarkerLayer ออก เพราะเราจะใช้ Icon วางลอยอยู่ตรงกลางจอแทน
                        ],
                      ),

                      // 🌟 หมุดลอยอยู่ตรงกลางหน้าจอ (Grab Style)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 35,
                          ), // ดันขึ้นให้ปลายแหลมชี้ตรงจุดกึ่งกลางพอดี
                          child: Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 50,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 🌟 ปุ่มกากบาทปิดหน้าต่าง
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 24),
                            color: Colors.black87,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),

                      // 🌟 ป้ายบอกใบ้การใช้งาน
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.pan_tool_rounded,
                                size: 18,
                                color: Color(0xFF7D3C98),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'เลื่อนแผนที่เพื่อปักหมุด',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7D3C98),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 🌟 ปุ่มดึงตำแหน่งปัจจุบัน (My Location)
                      Positioned(
                        bottom: 85,
                        right: 20,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: () async {
                            Position position =
                                await Geolocator.getCurrentPosition();
                            LatLng newPos = LatLng(
                              position.latitude,
                              position.longitude,
                            );
                            dialogMapController.move(newPos, 16.5);
                            tempLocation = newPos;
                          },
                          child: const Icon(
                            Icons.my_location,
                            color: Color(0xFF7D3C98),
                          ),
                        ),
                      ),

                      // 🌟 ปุ่มยืนยัน
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7D3C98),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            setState(() => currentLocation = tempLocation);
                            mapController.move(tempLocation, 16.5);
                            _getAddressFromLongdo(tempLocation);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'ยืนยันตำแหน่งนี้',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🌟 1. ระบบค้นหาด้วย Longdo SmartSearch API
        Autocomplete<Map<String, dynamic>>(
          displayStringForOption: (Map<String, dynamic> option) =>
              option['name'] ?? '',
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Map<String, dynamic>>.empty();
            }

            // 🌟 1. ถ้าผู้ใช้ยังพิมพ์ไม่หยุด ให้ยกเลิกการนับเวลาเก่าทิ้ง
            if (_debounce?.isActive ?? false) _debounce!.cancel();

            // 🌟 2. ใช้ Completer เพื่อรอส่งค่ากลับเมื่อนับเวลาเสร็จ
            Completer<Iterable<Map<String, dynamic>>> completer = Completer();

            // 🌟 3. เริ่มจับเวลา 500 มิลลิวินาที ถ้าหยุดพิมพ์ถึงจะยิง API
            _debounce = Timer(const Duration(milliseconds: 500), () async {
              final url = Uri.parse(
                'https://search.longdo.com/mapsearch/json/search?keyword=${textEditingValue.text}&limit=10&key=$longdoApiKey',
              );

              try {
                final response = await http.get(
                  url,
                  headers: {
                    'Referer': 'https://localhost',
                    'User-Agent': 'Mozilla/5.0',
                  },
                );

                if (response.statusCode == 200 &&
                    (response.body.trim().startsWith('{') ||
                        response.body.trim().startsWith('['))) {
                  final data = json.decode(response.body);
                  completer.complete(
                    List<Map<String, dynamic>>.from(data['data'] ?? []),
                  );
                } else {
                  completer.complete(
                    const Iterable<Map<String, dynamic>>.empty(),
                  );
                }
              } catch (e) {
                print("SmartSearch error: $e");
                completer.complete(
                  const Iterable<Map<String, dynamic>>.empty(),
                );
              }
            });

            return completer.future;
          },
          onSelected: (Map<String, dynamic> selection) {
            _selectSearchResult(selection['lat'], selection['lon']);
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาสถานที่',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 250,
                  width: MediaQuery.of(context).size.width - 32,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                        ),
                        title: Text(
                          option['name'] ?? 'ไม่ระบุชื่อ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          option['address'] ?? '',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // 🌟 2. ช่องข้อความรายละเอียดที่อยู่ (จะแสดงผลเฉพาะเมื่อ showAddressTextField เป็น true)
        if (widget.showAddressTextField) ...[
          const Text(
            'รายละเอียดที่อยู่',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: addressController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'กรอกที่อยู่ หรือปักหมุดบนแผนที่...',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (val) => widget.onLocationChanged(currentLocation, val),
          ),
          const SizedBox(height: 12),
        ],

        // 🌟 3. แผนที่ขนาดย่อ
        Stack(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: currentLocation,
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$maptilerApiKey',
                      userAgentPackageName: 'com.example.caretakerapp',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLocation,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: _openFullScreenMap),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                onPressed: _jumpToCurrentLocation,
                child: const Icon(Icons.my_location, color: Color(0xFF7D3C98)),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fullscreen, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'แตะเพื่อขยายและปักหมุด',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
