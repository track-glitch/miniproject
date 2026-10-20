import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// =======================================================
// 🌟 1. Widget หลัก (แสดงเป็นปุ่มสวยๆ ในหน้ากรอกข้อมูล)
// =======================================================
class LocationPickerWidget extends StatefulWidget {
  final LatLng initialLocation;
  final String initialAddress;
  final Function(LatLng, String) onLocationChanged;
  final bool showAddressTextField;

  const LocationPickerWidget({
    super.key,
    required this.initialLocation,
    required this.initialAddress,
    required this.onLocationChanged,
    this.showAddressTextField = true,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late LatLng currentLocation;
  late String currentAddress;

  @override
  void initState() {
    super.initState();
    currentLocation = widget.initialLocation;
    currentAddress = widget.initialAddress;
  }

  @override
  void didUpdateWidget(covariant LocationPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAddress != oldWidget.initialAddress &&
        widget.initialAddress.isNotEmpty) {
      currentAddress = widget.initialAddress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenMapPicker(
                  initialLocation: currentLocation,
                  initialAddress: currentAddress,
                ),
              ),
            );

            if (result != null) {
              setState(() {
                currentLocation = result['location'];
                currentAddress = result['address'];
              });
              widget.onLocationChanged(currentLocation, currentAddress);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD3C2F0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B59B6).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F5FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF9B59B6),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เลือกที่อยู่',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9B59B6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentAddress.isEmpty
                            ? 'แตะเพื่อค้นหาและปักหมุดแผนที่'
                            : currentAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: currentAddress.isEmpty
                              ? Colors.grey
                              : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =======================================================
// 🌟 2. หน้าต่างแผนที่เต็มจอ (สไตล์ Grab / Lineman)
// =======================================================
class FullScreenMapPicker extends StatefulWidget {
  final LatLng initialLocation;
  final String initialAddress;

  const FullScreenMapPicker({
    super.key,
    required this.initialLocation,
    required this.initialAddress,
  });

  @override
  State<FullScreenMapPicker> createState() => _FullScreenMapPickerState();
}

class _FullScreenMapPickerState extends State<FullScreenMapPicker> {
  late MapController mapController;
  late LatLng centerLocation;

  String longdoAddress = "กำลังดึงข้อมูลที่อยู่...";
  bool _isFetchingAddress = false; // 🌟 เพิ่มตัวแปรเช็กสถานะการโหลด
  TextEditingController detailAddressCtrl = TextEditingController();

  Timer? _searchDebounce;
  Timer? _mapDragDebounce;

  final String longdoApiKey = dotenv.env['LONGDO_API_KEY'] ?? '';
  final String maptilerApiKey = dotenv.env['MAPTILER_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    centerLocation = widget.initialLocation;

    // 🌟 1. ดักแยกเอาเฉพาะ "รายละเอียดบ้านเลขที่" มาใส่กล่องทันทีที่เปิดหน้าจอ
    String savedAddress = widget.initialAddress.trim();

    if (savedAddress.contains(',')) {
      // ถ้ารูปแบบใหม่มีลูกน้ำ (,) คั่น ให้ตัดเอาแค่ข้อความก่อนลูกน้ำ
      int lastCommaIndex = savedAddress.lastIndexOf(',');
      detailAddressCtrl.text = savedAddress.substring(0, lastCommaIndex).trim();
    } else if (savedAddress.startsWith('ต.') ||
        savedAddress.startsWith('แขวง')) {
      // ถ้าข้อมูลเก่าขึ้นต้นด้วย ตำบล หรือ แขวง แสดงว่าเซฟมาเพียวๆ ไม่มีบ้านเลขที่ ปล่อยกล่องว่างไปเลย
      detailAddressCtrl.text = '';
    } else {
      // กรณีอื่นๆ ยัดใส่กล่องไปก่อน แล้วให้ API ช่วยตัดตอนโหลดเสร็จ
      detailAddressCtrl.text = savedAddress;
    }

    _getAddressFromLongdo(centerLocation, isInit: true);
  }

  Future<void> _getAddressFromLongdo(
    LatLng location, {
    bool isInit = false,
  }) async {
    // 🌟 1. เช็กก่อนว่าหน้าจอยังเปิดอยู่ไหม ถ้าปิดไปแล้วให้หยุดทำงานทันที
    if (!mounted) return;

    setState(() => _isFetchingAddress = true);

    final url = Uri.parse(
      'https://api.longdo.com/map/services/address?lat=${location.latitude}&lon=${location.longitude}&format=json&key=$longdoApiKey',
    );
    try {
      // 🌟 2. ใส่ Headers กัน Longdo บล็อก (เหมือนตอนค้นหา)
      final response = await http.get(
        url,
        headers: {'Referer': 'https://localhost', 'User-Agent': 'Mozilla/5.0'},
      );

      // 🌟 3. เช็กอีกรอบเผื่อผู้ใช้กดปิดหน้าจอหนีตอนกำลังรอ http.get
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String fullAddress =
            '${data['subdistrict'] ?? ''} ${data['district'] ?? ''} ${data['province'] ?? ''} ${data['postcode'] ?? ''}'
                .trim();

        setState(() {
          longdoAddress = fullAddress.isEmpty
              ? "ไม่สามารถระบุที่อยู่ได้"
              : fullAddress;
          _isFetchingAddress = false;

          // 🌟 4. ช่วยตัดคำตำบล/อำเภอ ออกอีกแรง (สำหรับข้อมูลเก่าที่ไม่มีลูกน้ำคั่น)
          if (isInit && fullAddress.isNotEmpty) {
            String currentBoxText = detailAddressCtrl.text.trim();
            // เช็กว่าข้อความในกล่องลงท้ายด้วยตำบล/อำเภอพอดีเป๊ะไหม
            if (currentBoxText.endsWith(fullAddress)) {
              currentBoxText = currentBoxText
                  .replaceAll(fullAddress, '')
                  .trim();
              // ลบลูกน้ำที่อาจจะค้างอยู่ส่วนท้ายสุดทิ้ง
              if (currentBoxText.endsWith(',')) {
                currentBoxText = currentBoxText
                    .substring(0, currentBoxText.length - 1)
                    .trim();
              }
              detailAddressCtrl.text = currentBoxText;
            }
          }
        });
      } else {
        setState(() {
          longdoAddress = "ไม่สามารถระบุที่อยู่ได้";
          _isFetchingAddress = false;
        });
      }
    } catch (e) {
      // 🌟 เช็ก mounted ก่อนดักจับ Error
      if (mounted) {
        setState(() {
          longdoAddress = "ไม่สามารถระบุที่อยู่ได้";
          _isFetchingAddress = false;
        });
      }
    }
  }

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

    mapController.move(newPos, 16.5);
    centerLocation = newPos;
    _getAddressFromLongdo(newPos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── 🗺️ 1. ส่วนแผนที่ (ขยายเต็มพื้นที่ที่เหลือ) ──
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: centerLocation,
                    initialZoom: 16.5,
                    onPositionChanged: (position, hasGesture) {
                      if (position.center != null) {
                        centerLocation = position.center!;

                        // 🌟 เริ่มเลื่อนแผนที่ ให้โชว์สถานะว่ากำลังโหลดทันที
                        if (!(_mapDragDebounce?.isActive ?? false)) {
                          setState(() {
                            _isFetchingAddress = true;
                            longdoAddress = "กำลังดึงข้อมูลที่อยู่...";
                          });
                        }

                        if (_mapDragDebounce?.isActive ?? false) {
                          _mapDragDebounce!.cancel();
                        }

                        // 🌟 หน่วงเวลา 1.2 วินาที ถ้าหยุดเลื่อนถึงจะโหลดข้อมูล
                        _mapDragDebounce = Timer(
                          const Duration(milliseconds: 1200),
                          () {
                            _getAddressFromLongdo(centerLocation);
                          },
                        );
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$maptilerApiKey',
                      userAgentPackageName: 'com.example.caretakerapp',
                    ),
                  ],
                ),

                // หมุดตรงกลางหน้าจอ
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 35),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 50,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),

                // ปุ่มกลับไปตำแหน่งปัจจุบัน
                Positioned(
                  bottom: 20,
                  right: 15,
                  child: FloatingActionButton(
                    heroTag: "my_loc_btn",
                    backgroundColor: Colors.white,
                    onPressed: _jumpToCurrentLocation,
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF9B59B6),
                    ),
                  ),
                ),

                // ── 🔍 2. ช่องค้นหาสถานที่ลอยอยู่ด้านบนสุด ──
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Autocomplete<Map<String, dynamic>>(
                          displayStringForOption: (option) =>
                              option['name'] ?? '',
                          optionsBuilder: (textEditingValue) async {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<
                                Map<String, dynamic>
                              >.empty();
                            }
                            if (_searchDebounce?.isActive ?? false)
                              _searchDebounce!.cancel();
                            Completer<Iterable<Map<String, dynamic>>>
                            completer = Completer();

                            _searchDebounce = Timer(
                              const Duration(milliseconds: 500),
                              () async {
                                final url = Uri.parse(
                                  'https://search.longdo.com/mapsearch/json/search?keyword=${textEditingValue.text}&limit=8&key=$longdoApiKey',
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
                                          response.body.trim().startsWith(
                                            '[',
                                          ))) {
                                    final data = json.decode(response.body);
                                    completer.complete(
                                      List<Map<String, dynamic>>.from(
                                        data['data'] ?? [],
                                      ),
                                    );
                                  } else {
                                    completer.complete(
                                      const Iterable<
                                        Map<String, dynamic>
                                      >.empty(),
                                    );
                                  }
                                } catch (e) {
                                  completer.complete(
                                    const Iterable<
                                      Map<String, dynamic>
                                    >.empty(),
                                  );
                                }
                              },
                            );
                            return completer.future;
                          },
                          onSelected: (selection) {
                            LatLng newPos = LatLng(
                              selection['lat'],
                              selection['lon'],
                            );
                            mapController.move(newPos, 16.5);
                            centerLocation = newPos;
                            _getAddressFromLongdo(newPos);
                          },
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onEditingComplete,
                              ) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'ค้นหาที่อยู่ ชื่ออาคาร ซอย หรือ สถานที่',
                                      hintStyle: TextStyle(fontSize: 14),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Colors.grey,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                );
                              },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 250,
                                  ),
                                  width: MediaQuery.of(context).size.width - 80,
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
                                          maxLines: 1,
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 📝 3. แผงควบคุมด้านล่าง ──
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ตำแหน่งหมุด',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ผู้ให้บริการจะเดินทางไปตามหมุดที่คุณปัก',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // 🌟 ย้ายคำเตือนมาไว้ด้านบนให้เล็กลงและดูมินิมอล
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'ที่อยู่',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.info, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'ไม่เกี่ยวข้องกับตำแหน่งหมุด',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 🌟 กล่องข้อความกรอกรายละเอียด
                TextField(
                  controller: detailAddressCtrl,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'บ้านเลขที่ อาคาร ชั้น ซอย...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF9B59B6),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    // 🌟 เพิ่มปุ่ม (X) สำหรับลบข้อมูลเก่าทิ้งในคลิกเดียว
                    suffixIcon: detailAddressCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                detailAddressCtrl.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  // 🌟 อัปเดต UI ให้ปุ่มกากบาทโชว์/ซ่อน ตอนกำลังพิมพ์
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
                const SizedBox(
                  height: 4,
                ), // 🌟 ลดช่องว่างลงนิดนึง เพราะตัวนับอักษรจะกินพื้นที่ด้านล่างมาหน่อยนึงครับ
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      if (_isFetchingAddress)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF9B59B6),
                            ),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.location_on,
                            color: Color(0xFF9B59B6),
                            size: 20,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          longdoAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: _isFetchingAddress
                                ? Colors.grey.shade500
                                : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      String finalAddress =
                          "${detailAddressCtrl.text.trim()} $longdoAddress"
                              .trim();
                      Navigator.pop(context, {
                        'location': centerLocation,
                        'address': finalAddress,
                      });
                    },
                    child: const Text(
                      'ยืนยันหมุด',
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
        ],
      ),
    );
  }
}
