import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../logic/blocs/auth_bloc.dart';
import '../../logic/blocs/tracking_bloc.dart';
import '../../data/models/user_model.dart';

class TrackingScreen extends StatefulWidget {
  final UserModel user;
  const TrackingScreen({super.key, required this.user});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Salesman Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthSignOutRequested());
              context.read<TrackingBloc>().add(TrackingStopped(widget.user.uid));
            },
          ),
        ],
      ),
      body: BlocListener<TrackingBloc, TrackingState>(
        listener: (context, state) {
          if (state is TrackingActive && state.lastLocation != null) {
            _mapController.move(
              LatLng(state.lastLocation!.lat, state.lastLocation!.lng),
              15.0,
            );
          }
        },
        child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600.w > 600 ? 600 : double.infinity),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25.r,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Icon(Icons.person, size: 30.r, color: Colors.blue),
                      ),
                      title: Text(widget.user.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                      subtitle: Text(widget.user.email, style: TextStyle(fontSize: 14.sp)),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  BlocBuilder<TrackingBloc, TrackingState>(
                    builder: (context, state) {
                      bool isTracking = state is TrackingActive;
                      LatLng currentCenter = const LatLng(20.5937, 78.9629); // Default India
                      if (state is TrackingActive && state.lastLocation != null) {
                        currentCenter = LatLng(state.lastLocation!.lat, state.lastLocation!.lng);
                      }
    
                      return Column(
                        children: [
                          Container(
                            height: 350.h > 400 ? 400 : 350.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.r),
                              child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: currentCenter,
                                  initialZoom: 15.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.flutterdevyt.aiapp',
                                  ),
                                  if (isTracking && state.lastLocation != null)
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(state.lastLocation!.lat, state.lastLocation!.lng),
                                          width: 40.r,
                                          height: 40.r,
                                          child: Icon(Icons.location_on, color: Colors.red, size: 35.r),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: isTracking ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: isTracking ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isTracking ? Icons.sensors : Icons.sensors_off,
                                  color: isTracking ? Colors.green : Colors.grey,
                                  size: 24.r,
                                ),
                                SizedBox(width: 12.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTracking ? 'Tracking Active' : 'Tracking Inactive',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: isTracking ? Colors.green : Colors.grey),
                                    ),
                                    if (isTracking && state is TrackingActive)
                                      Text(
                                        'Interval: ${state.config.updateIntervalSeconds}s',
                                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                if (isTracking)
                                  Container(
                                    width: 10.r,
                                    height: 10.r,
                                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 24.h),
                          
                          if (isTracking && state is TrackingActive && state.lastLocation != null)
                            Card(
                              elevation: 0,
                              color: Colors.blue.withOpacity(0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, color: Colors.blue, size: 20.r),
                                        SizedBox(width: 8.w),
                                        Text('Last Known Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      state.lastLocation!.address,
                                      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Updated: ${DateFormat('hh:mm:ss a').format(state.lastLocation!.timestamp)}',
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          SizedBox(height: 32.h),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 55.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isTracking ? Colors.red : Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                elevation: 2,
                              ),
                              onPressed: () {
                                if (isTracking) {
                                  context.read<TrackingBloc>().add(TrackingStopped(widget.user.uid));
                                } else {
                                  context.read<TrackingBloc>().add(TrackingStarted(widget.user));
                                }
                              },
                              child: Text(
                                isTracking ? 'STOP TRACKING' : 'START TRACKING',
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          SizedBox(height: 40.h),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
