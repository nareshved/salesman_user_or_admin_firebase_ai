import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/location_model.dart';
import '../../data/models/user_model.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'salesman_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _adminRepo = AdminRepository();
  final _mapController = MapController();
  
  // Selected salesman for tracking focus
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          
          if (isWide) {
            return Row(
              children: [
                // Side Panel
                SizedBox(
                  width: 350,
                  child: Material(
                    elevation: 4,
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Active Salesmen',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const Divider(),
                        Expanded(child: _buildPureSalesmanList()),
                      ],
                    ),
                  ),
                ),
                // Map Area
                Expanded(
                  child: Stack(
                    children: [
                      _buildMap(),
                      _buildHeaderOverlay(true),
                    ],
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              _buildMap(),
              _buildHeaderOverlay(false),
              _buildDraggableSalesmanList(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(const LatLng(28.6139, 77.2090), 12.0);
          setState(() {
            _selectedUserId = null;
          });
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildMap() {
    return StreamBuilder<List<LocationModel>>(
      stream: _adminRepo.getActiveLocations(),
      builder: (context, snapshot) {
        final locations = snapshot.data ?? [];
        return FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(28.6139, 77.2090),
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.admin_sales_app',
            ),
            MarkerLayer(
              markers: locations.map((loc) {
                final isSelected = loc.userId == _selectedUserId;
                final diff = DateTime.now().difference(loc.timestamp).inMinutes;
                final markerColor = diff < 10 ? Colors.green : (diff < 60 ? Colors.orange : Colors.red);

                return Marker(
                  point: LatLng(loc.lat, loc.lng),
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedUserId = loc.userId;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Text(
                            loc.name,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          size: isSelected ? 40 : 30,
                          color: markerColor,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderOverlay(bool isWide) {
    return Positioned(
      top: 50,
      left: isWide ? 40 : 20,
      right: isWide ? null : 20,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
        child: Container(
          width: isWide ? 500 : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: Color(0xFF6366F1)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.people_outline),
                tooltip: 'Manage Salesmen',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SalesmanManagementScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                onPressed: () => AuthRepository().signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableSalesmanList() {
    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Sales Team',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                child: _buildPureSalesmanList(scrollController: scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPureSalesmanList({ScrollController? scrollController}) {
    return StreamBuilder<List<UserModel>>(
      stream: _adminRepo.getSalesmen(),
      builder: (context, salesmanSnapshot) {
        final salesmen = salesmanSnapshot.data ?? [];
        if (salesmen.isEmpty) {
          return const Center(child: Text('No salesmen found'));
        }
        
        return StreamBuilder<List<LocationModel>>(
          stream: _adminRepo.getActiveLocations(),
          builder: (context, locSnapshot) {
            final activeLocs = locSnapshot.data ?? [];
            
            return ListView.builder(
              controller: scrollController,
              itemCount: salesmen.length,
              itemBuilder: (context, index) {
                final user = salesmen[index];
                final isSelected = user.uid == _selectedUserId;
                final myLoc = activeLocs.where((l) => l.userId == user.uid).firstOrNull;
                
                String statusText = user.status;
                Color statusColor = Colors.grey;
                
                if (myLoc != null) {
                  final diff = DateTime.now().difference(myLoc.timestamp).inMinutes;
                  if (diff < 10) {
                    statusText = 'Active';
                    statusColor = Colors.green;
                  } else {
                    statusText = 'Inactive (${diff}m ago)';
                    statusColor = Colors.orange;
                  }
                } else if (user.status == 'pending') {
                  statusText = 'Pending Signup';
                  statusColor = Colors.blue;
                }

                return ListTile(
                  selected: isSelected,
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(
                      user.status == 'pending' ? Icons.hourglass_empty : Icons.person,
                      color: statusColor,
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: $statusText', style: TextStyle(color: statusColor, fontSize: 12)),
                      if (myLoc != null)
                        Text(
                          myLoc.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.history, color: Color(0xFF6366F1)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryScreen(userId: user.uid, userName: user.name),
                      ),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedUserId = user.uid;
                    });
                    if (myLoc != null) {
                      _mapController.move(LatLng(myLoc.lat, myLoc.lng), 15.0);
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

}
