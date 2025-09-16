import 'package:flutter/material.dart';
import 'api_service.dart';

class BorrowingsPage extends StatefulWidget {
  const BorrowingsPage({super.key});

  @override
  State<BorrowingsPage> createState() => _BorrowingsPageState();
}

class _BorrowingsPageState extends State<BorrowingsPage> {
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);

  final _formKey = GlobalKey<FormState>();
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _fineController = TextEditingController();
  
  List<Map<String, dynamic>> _borrowings = [];
  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  int? _editingId;
  String? _selectedBook;
  String? _selectedMember;
  String _selectedStatus = 'Borrowed';

  @override
  void initState() {
    super.initState();
    _loadBorrowings();
    _loadBooks();
    _loadMembers();
  }

  @override
  void dispose() {
    _dueDateController.dispose();
    _notesController.dispose();
    _fineController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _loadBooks() async {
    try {
      final books = await ApiService.getBooks();
      if (mounted) _safeSetState(() => _books = books);
    } catch (e) {
      if (mounted) _showMessage('Failed to load books', isError: true);
    }
  }

  Future<void> _loadMembers() async {
    try {
      final members = await ApiService.getMembers();
      if (mounted) _safeSetState(() => _members = members);
    } catch (e) {
      if (mounted) _showMessage('Failed to load members', isError: true);
    }
  }

  Future<void> _loadBorrowings() async {
    _safeSetState(() => _isLoading = true);
    try {
      final borrowings = await ApiService.getBorrowings();
      if (mounted) _safeSetState(() => _borrowings = borrowings);
    } catch (e) {
      if (mounted) _showMessage('Failed to load borrowings', isError: true);
    } finally {
      if (mounted) _safeSetState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _dueDateController.clear();
    _notesController.clear();
    _fineController.clear();
    _safeSetState(() {
      _editingId = null;
      _selectedBook = null;
      _selectedMember = null;
      _selectedStatus = 'Borrowed';
    });
  }

  void _editBorrowing(Map<String, dynamic> borrowing) {
    _safeSetState(() {
      _editingId = borrowing['id'];
      _selectedBook = borrowing['book_title'];
      _selectedMember = borrowing['member_name'];
      _dueDateController.text = borrowing['due_date'] ?? '';
      _notesController.text = borrowing['notes'] ?? '';
      _fineController.text = borrowing['fine_amount']?.toString() ?? '0.00';
      _selectedStatus = borrowing['status'] ?? 'Borrowed';
    });
  }

  Future<void> _saveBorrowing() async {
    if (!_formKey.currentState!.validate()) return;

    final borrowingData = {
      'book_title': _selectedBook,
      'member_name': _selectedMember,
      'due_date': _dueDateController.text.trim(),
      'status': _selectedStatus,
      'notes': _notesController.text.trim(),
      'fine_amount': double.tryParse(_fineController.text) ?? 0.00,
    };

    try {
      bool success;
      if (_editingId != null) {
        success = await ApiService.updateBorrowing(_editingId!, borrowingData);
      } else {
        success = await ApiService.addBorrowing(borrowingData);
      }

      if (mounted) {
        if (success) {
          _showMessage('Borrowing ${_editingId != null ? 'updated' : 'added'} successfully!');
          _clearForm();
          _loadBorrowings();
        } else {
          _showMessage('Failed to save borrowing.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showMessage('An error occurred.', isError: true);
    }
  }

  Future<void> _deleteBorrowing(int id, String bookTitle) async {
    final confirmed = await _showDeleteConfirmation(bookTitle);
    if (!confirmed || !mounted) return;

    try {
      final success = await ApiService.deleteBorrowing(id);
      if (mounted) {
        if (success) {
          _showMessage('Borrowing deleted successfully!');
          _loadBorrowings();
        } else {
          _showMessage('Failed to delete borrowing.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showMessage('An error occurred.', isError: true);
    }
  }

  Future<bool> _showDeleteConfirmation(String bookTitle) async {
    if (!mounted) return false;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Borrowing'),
        content: Text('Are you sure you want to delete the borrowing record for "$bookTitle"?'),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'borrowed':
        return warningColor;
      case 'returned':
        return successColor;
      case 'overdue':
        return errorColor;
      case 'lost':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'borrowed':
        return Icons.library_books;
      case 'returned':
        return Icons.check_circle;
      case 'overdue':
        return Icons.warning;
      case 'lost':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Not set';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  bool _isOverdue(String? dueDateStr, String status) {
    if (dueDateStr == null || status.toLowerCase() == 'returned') return false;
    try {
      final dueDate = DateTime.parse(dueDateStr);
      return DateTime.now().isAfter(dueDate) && status.toLowerCase() == 'borrowed';
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 20),
            _buildBorrowingForm(),
            const SizedBox(height: 20),
            Expanded(child: _buildBorrowingsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        const Icon(Icons.library_books, size: 32, color: primaryColor),
        const SizedBox(width: 12),
        const Text(
          'Manage Borrowings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const Spacer(),
        Text(
          '${_borrowings.length} ${_borrowings.length == 1 ? 'borrowing' : 'borrowings'}',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBorrowingForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _editingId != null ? Icons.edit : Icons.add,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _editingId != null ? 'Edit Borrowing' : 'Add New Borrowing',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Row 1: Book and Member Selection
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedBook,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Book*',
                        hintText: 'Select book',
                        prefixIcon: Icon(Icons.book),
                      ),
                      items: _books.map<DropdownMenuItem<String>>((book) {
                        final isAvailable = (book['available'] ?? 0) > 0;
                        return DropdownMenuItem<String>(
                          value: book['title'],
                          enabled: isAvailable || _editingId != null,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  book['title'] ?? 'Untitled',
                                  style: TextStyle(
                                    color: isAvailable || _editingId != null 
                                        ? Colors.black 
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              if (!isAvailable && _editingId == null)
                                const Text(
                                  ' (Unavailable)',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        _safeSetState(() => _selectedBook = newValue);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a book';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedMember,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Member*',
                        hintText: 'Select member',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _members.map<DropdownMenuItem<String>>((member) {
                        return DropdownMenuItem<String>(
                          value: member['name'],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member['name'] ?? 'Unnamed'),
                              Text(
                                '${member['member_type'] ?? 'Unknown'} - ${member['member_id'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        _safeSetState(() => _selectedMember = newValue);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a member';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Row 2: Due Date and Status
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dueDateController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Due Date*',
                        hintText: 'YYYY-MM-DD',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _editingId != null 
                              ? (DateTime.tryParse(_dueDateController.text) ?? DateTime.now().add(const Duration(days: 14)))
                              : DateTime.now().add(const Duration(days: 14)),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          _dueDateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please select due date';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.info),
                      ),
                      items: ['Borrowed', 'Returned', 'Overdue', 'Lost'].map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                size: 16,
                                color: _getStatusColor(status),
                              ),
                              const SizedBox(width: 8),
                              Text(status),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        _safeSetState(() => _selectedStatus = newValue ?? 'Borrowed');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Row 3: Fine Amount and Notes
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fineController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Fine Amount',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.money),
                        prefixText: '\$ ',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final amount = double.tryParse(value);
                          if (amount == null || amount < 0) {
                            return 'Please enter valid amount';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Notes',
                        hintText: 'Additional notes or comments',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveBorrowing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: Icon(_editingId != null ? Icons.update : Icons.add),
                    label: Text(_editingId != null ? 'Update Borrowing' : 'Add Borrowing'),
                  ),
                  if (_editingId != null) ...[
                    const SizedBox(width: 15),
                    OutlinedButton.icon(
                      onPressed: _clearForm,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                    ),
                  ],
                  const Spacer(),
                  if (_editingId != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Editing: $_selectedBook',
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBorrowingsList() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.list, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Borrowing Records',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                        SizedBox(height: 16),
                        Text('Loading borrowings...'),
                      ],
                    ),
                  )
                : _borrowings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.library_books_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No borrowing records found',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add your first borrowing record using the form above',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _borrowings.length,
                        itemBuilder: (context, index) {
                          final borrowing = _borrowings[index];
                          return _buildBorrowingListItem(borrowing, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowingListItem(Map<String, dynamic> borrowing, int index) {
    final status = borrowing['status'] ?? 'Unknown';
    final statusColor = _getStatusColor(status);
    final isCurrentlyEditing = _editingId == borrowing['id'];
    final isOverdue = _isOverdue(borrowing['due_date'], status);
    final actualStatusColor = isOverdue ? errorColor : statusColor;
    final actualStatus = isOverdue ? 'Overdue' : status;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCurrentlyEditing ? 4 : 1,
      color: isCurrentlyEditing ? primaryColor.withOpacity(0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isCurrentlyEditing 
            ? const BorderSide(color: primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: actualStatusColor,
          radius: 25,
          child: Icon(
            _getStatusIcon(actualStatus),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          borrowing['book_title'] ?? 'Unknown Book',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member: ${borrowing['member_name'] ?? 'Unknown'}'),
            Text('Due: ${_formatDate(borrowing['due_date'])}'),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: actualStatusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                actualStatus,
                style: TextStyle(
                  color: actualStatusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: isCurrentlyEditing ? primaryColor : Colors.blue,
              ),
              onPressed: () => _editBorrowing(borrowing),
              tooltip: 'Edit Borrowing',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: errorColor),
              onPressed: () => _deleteBorrowing(
                borrowing['id'],
                borrowing['book_title'] ?? 'Unknown Book',
              ),
              tooltip: 'Delete Borrowing',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Borrowing Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Borrow Date', _formatDate(borrowing['borrow_date'])),
                _buildDetailRow('Due Date', _formatDate(borrowing['due_date'])),
                if (borrowing['return_date'] != null)
                  _buildDetailRow('Return Date', _formatDate(borrowing['return_date'])),
                if (borrowing['fine_amount'] != null && borrowing['fine_amount'] > 0)
                  _buildDetailRow('Fine Amount', '\$${borrowing['fine_amount']}'),
                if (borrowing['notes'] != null && borrowing['notes'].toString().isNotEmpty)
                  _buildDetailRow('Notes', borrowing['notes']),
                if (borrowing['issued_by'] != null)
                  _buildDetailRow('Issued By', borrowing['issued_by']),
                if (borrowing['returned_to'] != null)
                  _buildDetailRow('Returned To', borrowing['returned_to']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}