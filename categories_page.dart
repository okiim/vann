import 'package:flutter/material.dart';
import 'api_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _loadCategories() async {
    _safeSetState(() => _isLoading = true);
    try {
      final categories = await ApiService.getCategories();
      if (mounted) {
        _safeSetState(() => _categories = categories);
      }
    } catch (e) {
      if (mounted) _showMessage('Failed to load categories', isError: true);
    } finally {
      if (mounted) _safeSetState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _safeSetState(() => _editingId = null);
  }

  void _editCategory(Map<String, dynamic> category) {
    _safeSetState(() {
      _editingId = category['id'];
      _nameController.text = category['name'] ?? '';
      _descriptionController.text = category['description'] ?? '';
    });
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final categoryData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    try {
      bool success;
      if (_editingId != null) {
        success = await ApiService.updateCategory(_editingId!, categoryData);
      } else {
        success = await ApiService.addCategory(categoryData);
      }

      if (mounted) {
        if (success) {
          _showMessage('Category ${_editingId != null ? 'updated' : 'added'} successfully!');
          _clearForm();
          _loadCategories();
        } else {
          _showMessage('Failed to save category.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showMessage('An error occurred.', isError: true);
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirmed = await _showDeleteConfirmation(name);
    if (!confirmed || !mounted) return;

    try {
      final success = await ApiService.deleteCategory(id);
      if (mounted) {
        if (success) {
          _showMessage('Category deleted successfully!');
          _loadCategories();
        } else {
          _showMessage('Failed to delete category.', isError: true);
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
        title: const Text('Delete Category'),
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
              'Manage Categories',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildCategoryForm(),
            const SizedBox(height: 20),
            Expanded(child: _buildCategoriesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryForm() {
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
                _editingId != null ? 'Edit Category' : 'Add New Category',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Category Name*',
                  hintText: 'e.g., Fiction, Science, History',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Description',
                  hintText: 'Describe this category',
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_editingId != null ? 'Update Category' : 'Add Category'),
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

  Widget _buildCategoriesList() {
    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Existing Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? const Center(
                        child: Text(
                          'No categories found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: primaryColor,
                                child: Icon(Icons.category, color: Colors.white),
                              ),
                              title: Text(category['name'] ?? 'Unnamed Category'),
                              subtitle: category['description'] != null && 
                                  category['description'].toString().isNotEmpty
                                  ? Text(category['description'])
                                  : const Text('No description'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: primaryColor),
                                    onPressed: () => _editCategory(category),
                                    tooltip: 'Edit Category',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: errorColor),
                                    onPressed: () => _deleteCategory(
                                      category['id'],
                                      category['name'] ?? 'Unnamed Category',
                                    ),
                                    tooltip: 'Delete Category',
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