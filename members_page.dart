import 'package:flutter/material.dart';
import 'api_service.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  int? _editingId;
  String _selectedMemberType = 'Student';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _loadMembers() async {
    _safeSetState(() => _isLoading = true);
    try {
      final members = await ApiService.getMembers();
      if (mounted) _safeSetState(() => _members = members);
    } catch (e) {
      if (mounted) _showMessage('Failed to load members', isError: true);
    } finally {
      if (mounted) _safeSetState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _safeSetState(() {
      _editingId = null;
      _selectedMemberType = 'Student';
    });
  }

  void _editMember(Map<String, dynamic> member) {
    _safeSetState(() {
      _editingId = member['id'];
      _nameController.text = member['name'] ?? '';
      _emailController.text = member['email'] ?? '';
      _phoneController.text = member['phone'] ?? '';
      _addressController.text = member['address'] ?? '';
      _selectedMemberType = member['member_type'] ?? 'Student';
    });
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    final memberData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'member_type': _selectedMemberType,
    };

    try {
      bool success;
      if (_editingId != null) {
        success = await ApiService.updateMember(_editingId!, memberData);
      } else {
        success = await ApiService.addMember(memberData);
      }

      if (mounted) {
        if (success) {
          _showMessage('Member ${_editingId != null ? 'updated' : 'added'} successfully!');
          _clearForm();
          _loadMembers();
        } else {
          _showMessage('Failed to save member.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showMessage('An error occurred.', isError: true);
    }
  }

  Future<void> _deleteMember(int id, String name) async {
    final confirmed = await _showDeleteConfirmation(name);
    if (!confirmed || !mounted) return;

    try {
      final success = await ApiService.deleteMember(id);
      if (mounted) {
        if (success) {
          _showMessage('Member deleted successfully!');
          _loadMembers();
        } else {
          _showMessage('Failed to delete member.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showMessage('An error occurred.', isError: true);
    }
  }

  Future<bool> _showDeleteConfirmation(String name) async {
    if (!mounted) return false;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? errorColor : successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Members',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 20),
            _buildMemberForm(),
            const SizedBox(height: 20),
            Expanded(child: _buildMembersList()),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberForm() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingId != null ? 'Edit Member' : 'Add New Member',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Full Name*',
                        hintText: 'Enter member name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter member name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedMemberType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Member Type',
                      ),
                      items: ['Student', 'Faculty', 'Staff', 'Public'].map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        _safeSetState(() => _selectedMemberType = newValue ?? 'Student');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email*',
                        hintText: 'Enter email address',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Phone',
                        hintText: 'Enter phone number',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Address',
                  hintText: 'Enter address',
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_editingId != null ? 'Update Member' : 'Add Member'),
                  ),
                  if (_editingId != null) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _clearForm,
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Existing Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? const Center(
                        child: Text(
                          'No members found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryColor,
                                child: Text(
                                  (member['name'] ?? 'M')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(member['name'] ?? 'Unnamed Member'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email: ${member['email'] ?? 'No email'}'),
                                  Text('Type: ${member['member_type'] ?? 'Unknown'}'),
                                  if (member['phone'] != null && member['phone'].toString().isNotEmpty)
                                    Text('Phone: ${member['phone']}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: primaryColor),
                                    onPressed: () => _editMember(member),
                                    tooltip: 'Edit Member',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: errorColor),
                                    onPressed: () => _deleteMember(
                                      member['id'],
                                      member['name'] ?? 'Unnamed Member',
                                    ),
                                    tooltip: 'Delete Member',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}