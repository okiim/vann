import 'package:flutter/material.dart';
import 'api_service.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _quantityController = TextEditingController();
  
  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  int? _editingId;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.getCategories();
      if (mounted) _safeSetState(() => _categories = categories);
    } catch (e) {
      if (mounted) _showMessage('Failed to load categories', isError: true);
    }
  }

  Future<void> _loadBooks() async {
    _safeSetState(() => _isLoading = true);
    try {
      final books = await ApiService.getBooks();
      if (mounted) _safeSetState(() => _books = books);
    } catch (e) {
      if (mounted) _showMessage('Failed to load books', isError: true);
    } finally {
      if (mounted) _safeSetState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _authorController.clear();
    _isbnController.clear();
    _quantityController.clear();
    _safeSetState(() {
      _editingId = null;
      _selectedCategory = null;
    });
  }

  void _editBook(Map<String, dynamic> book) {
    _safeSetState(() {
      _editingId = book['id'];
      _titleController.text = book['title'] ?? '';
      _authorController.text = book['author'] ?? '';
      _isbnController.text = book['isbn'] ?? '';
      _quantityController.text = book['quantity']?.toString() ?? '';
      _selectedCategory = book['category'];
    });
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    final bookData = {
      'title': _titleController.text.trim(),
      'author': _authorController.text.trim(),
      'isbn': _isbnController.text.trim(),
      'quantity': int.tryParse(_quantityController.text) ?? 1,
      'category': _selectedCategory,
    };

    try {
      bool success;
      if (_editingId != null) {
        success = await ApiService.updateBook(_editingId!, bookData);
      } else {
        success = await ApiService.addBook(bookData);
      }

      if (mounted) {
        if (success) {
          _showMessage('Book ${_editingId != null ? 'updated' : 'added'} successfully!');
          _clearForm();
          _loadBooks();
        } else {
          _showMessage('Failed to save book.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showMessage('An error occurred.', isError: true);
    }
  }

  Future<void> _deleteBook(int id, String title) async {
    final confirmed = await _showDeleteConfirmation(title);
    if (!confirmed || !mounted) return;

    try {
      final success = await ApiService.deleteBook(id);
      if (mounted) {
        if (success) {
          _showMessage('Book deleted successfully!');
          _loadBooks();
        } else {
          _showMessage('Failed to delete book.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showMessage('An error occurred.', isError: true);
    }
  }

  Future<bool> _showDeleteConfirmation(String title) async {
    if (!mounted) return false;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "$title"?'),
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
              'Manage Books',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 20),
            _buildBookForm(),
            const SizedBox(height: 20),
            Expanded(child: _buildBooksList()),
          ],
        ),
      ),
    );
  }

  Widget _buildBookForm() {
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
                _editingId != null ? 'Edit Book' : 'Add New Book',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Book Title*',
                        hintText: 'Enter book title',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter book title';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Author*',
                        hintText: 'Enter author name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter author name';
                        }
                        return null;
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
                      controller: _isbnController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'ISBN',
                        hintText: 'Enter ISBN',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Quantity*',
                        hintText: 'Number of copies',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter quantity';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 1) {
                          return 'Please enter valid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Category',
                        hintText: 'Select category',
                      ),
                      items: _categories.map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category['name'],
                          child: Text(category['name'] ?? 'Unnamed Category'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        _safeSetState(() => _selectedCategory = newValue);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_editingId != null ? 'Update Book' : 'Add Book'),
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

  Widget _buildBooksList() {
    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Existing Books',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _books.isEmpty
                    ? const Center(
                        child: Text(
                          'No books found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _books.length,
                        itemBuilder: (context, index) {
                          final book = _books[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: primaryColor,
                                child: Icon(Icons.book, color: Colors.white),
                              ),
                              title: Text(book['title'] ?? 'Untitled Book'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Author: ${book['author'] ?? 'Unknown'}'),
                                  if (book['isbn'] != null && book['isbn'].toString().isNotEmpty)
                                    Text('ISBN: ${book['isbn']}'),
                                  Text('Quantity: ${book['quantity'] ?? 0}'),
                                  if (book['category'] != null)
                                    Text('Category: ${book['category']}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: primaryColor),
                                    onPressed: () => _editBook(book),
                                    tooltip: 'Edit Book',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: errorColor),
                                    onPressed: () => _deleteBook(
                                      book['id'],
                                      book['title'] ?? 'Untitled Book',
                                    ),
                                    tooltip: 'Delete Book',
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