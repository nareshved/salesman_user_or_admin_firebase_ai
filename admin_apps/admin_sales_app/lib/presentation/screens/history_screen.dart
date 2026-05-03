import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/location_model.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const HistoryScreen({super.key, required this.userId, required this.userName});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _adminRepo = AdminRepository();
  DateTime _selectedDate = DateTime.now();
  List<LocationModel> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _adminRepo.getLocationHistory(widget.userId, _selectedDate);
      setState(() {
        _history = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final polylinePoints = _history.map((loc) => LatLng(loc.lat, loc.lng)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              DateFormat('dd MMM yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          
          final mapWidget = Expanded(
            flex: 2,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: polylinePoints.isNotEmpty 
                    ? polylinePoints.first 
                    : const LatLng(28.6139, 77.2090),
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                if (polylinePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: polylinePoints,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: _history.map((loc) {
                    return Marker(
                      point: LatLng(loc.lat, loc.lng),
                      width: 10,
                      height: 10,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );

          final listWidget = Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                      ? const Center(child: Text('No history found for this date'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _history.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final loc = _history[index];
                            return ListTile(
                              leading: Text(
                                DateFormat('HH:mm').format(loc.timestamp),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              title: Text(
                                loc.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                '${loc.lat.toStringAsFixed(4)}, ${loc.lng.toStringAsFixed(4)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
            ),
          );

          if (isWide) {
            return Row(
              children: [
                mapWidget,
                const VerticalDivider(width: 1),
                SizedBox(width: 350, child: listWidget),
              ],
            );
          }

          return Column(
            children: [
              mapWidget,
              listWidget,
            ],
          );
        },
      ),
    );
  }
}
