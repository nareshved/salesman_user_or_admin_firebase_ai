import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/user_model.dart';

class SalesmanManagementScreen extends StatefulWidget {
  const SalesmanManagementScreen({super.key});

  @override
  State<SalesmanManagementScreen> createState() => _SalesmanManagementScreenState();
}

class _SalesmanManagementScreenState extends State<SalesmanManagementScreen> {
  final _adminRepo = AdminRepository();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _processingUids = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manage Salesmen'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSearchAndAdd(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildSalesmanList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndAdd() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddSalesmanDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add New'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesmanList() {
    return StreamBuilder<List<UserModel>>(
      stream: _adminRepo.getSalesmen(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ensure your Firestore user document has role: "admin".',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allSalesmen = snapshot.data ?? [];
        final filteredSalesmen = allSalesmen.where((u) {
          return u.name.toLowerCase().contains(_searchQuery) || 
                 u.email.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredSalesmen.isEmpty) {
          return const Center(
            child: Text('No salesmen found matching your search.'),
          );
        }

        return ListView.separated(
          itemCount: filteredSalesmen.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = filteredSalesmen[index];
            return _buildSalesmanCard(user);
          },
        );
      },
    );
  }

  Widget _buildSalesmanCard(UserModel user) {
    final bool isDisabled = user.status == 'disabled';
    final bool isPending = user.status == 'pending';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (isPending ? Colors.orange : (isDisabled ? Colors.red : Colors.green)).withOpacity(0.1),
          child: Icon(
            isPending ? Icons.hourglass_empty : Icons.person, 
            color: isPending ? Colors.orange : (isDisabled ? Colors.red : Color(0xFF64748B))
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isPending ? Colors.orange : (isDisabled ? Colors.red : Colors.green)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isPending ? 'Pending Signup' : (isDisabled ? 'Disabled' : 'Active'),
                style: TextStyle(
                  color: isPending ? Colors.orange : (isDisabled ? Colors.red : Colors.green),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: _processingUids.contains(user.uid)
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                    onPressed: () => _showEditSalesmanDialog(user),
                  ),
                  if (!isPending)
                    Switch(
                      value: !isDisabled,
                      onChanged: (val) async {
                        setState(() => _processingUids.add(user.uid));
                        try {
                          await _adminRepo.updateSalesmanStatus(
                              user.uid, val ? 'idle' : 'disabled');
                        } finally {
                          if (mounted) setState(() => _processingUids.remove(user.uid));
                        }
                      },
                      activeColor: const Color(0xFF6366F1),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(user),
                  ),
                ],
              ),
      ),
    );
  }

  void _showAddSalesmanDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    bool isDialogLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Salesman'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Note: This creates a profile. The salesman must sign up with this email in the app.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDialogLoading ? null : () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: isDialogLoading ? null : () async {
                if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                  setDialogState(() => isDialogLoading = true);
                  try {
                    await _adminRepo.addSalesman(
                      email: emailController.text.trim(),
                      name: nameController.text.trim(),
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Salesman profile created.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    setDialogState(() => isDialogLoading = false);
                  }
                }
              },
              child: isDialogLoading 
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSalesmanDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    bool isDialogLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Salesman'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          actions: [
            TextButton(
                onPressed: isDialogLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isDialogLoading
                  ? null
                  : () async {
                      if (nameController.text.isNotEmpty) {
                        setDialogState(() => isDialogLoading = true);
                        try {
                          await _adminRepo.updateSalesmanName(
                              user.uid, nameController.text.trim());
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name updated.')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } finally {
                          setDialogState(() => isDialogLoading = false);
                        }
                      }
                    },
              child: isDialogLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Salesman?'),
        content: Text('Are you sure you want to remove ${user.name}? This will stop tracking.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _processingUids.add(user.uid));
              try {
                await _adminRepo.deleteSalesman(user.uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${user.name} removed.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _processingUids.remove(user.uid));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
