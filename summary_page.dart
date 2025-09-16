import 'package:flutter/material.dart';
import 'api_service.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _borrowings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _loadAllData() async {
    _safeSetState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getBooks(),
        ApiService.getMembers(),
        ApiService.getBorrowings(),
      ]);

      if (mounted) {
        _safeSetState(() {
          _categories = results[0];
          _books = results[1];
          _members = results[2];
          _borrowings = results[3];
        });
      }
    } catch (e) {
      print('Error loading summary data: $e');
    } finally {
      if (mounted) _safeSetState(() => _isLoading = false);
    }
  }

  Map<String, int> _getBorrowingStatusCounts() {
    final counts = {'Borrowed': 0, 'Returned': 0, 'Overdue': 0};
    for (var borrowing in _borrowings) {
      final status = borrowing['status'] ?? 'Borrowed';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, List<Map<String, dynamic>>> _getBooksByCategory() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var book in _books) {
      final category = book['category'] ?? 'Uncategorized';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(book);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
              SizedBox(height: 16),
              Text('Loading summary data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Library System Summary',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 30),
            
            _buildOverviewSection(),
            const SizedBox(height: 30),
            
            _buildBorrowingStatusSection(),
            const SizedBox(height: 30),
            
            _buildBooksByCategorySection(),
            const SizedBox(height: 30),
            
            _buildMembersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Categories', _categories.length.toString(), Icons.category, successColor),
            _buildStatCard('Books', _books.length.toString(), Icons.book, primaryColor),
            _buildStatCard('Members', _members.length.toString(), Icons.people, warningColor),
            _buildStatCard('Borrowings', _borrowings.length.toString(), Icons.library_books, errorColor),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowingStatusSection() {
    final statusCounts = _getBorrowingStatusCounts();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.library_books, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Borrowing Status',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_borrowings.length} total',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard('Borrowed', statusCounts['Borrowed']!, Colors.orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatusCard('Returned', statusCounts['Returned']!, successColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatusCard('Overdue', statusCounts['Overdue']!, errorColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, int count, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksByCategorySection() {
    final booksByCategory = _getBooksByCategory();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: successColor),
                const SizedBox(width: 8),
                const Text(
                  'Books by Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_books.length} total books',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            booksByCategory.isEmpty
                ? const Text('No books found')
                : Column(
                    children: booksByCategory.entries.map((entry) {
                      final categoryName = entry.key;
                      final books = entry.value;
                      
                      return ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: successColor,
                          radius: 20,
                          child: Text(
                            books.length.toString(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          categoryName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${books.length} books'),
                        children: books.map((book) {
                          return ListTile(
                            leading: const Icon(Icons.book, size: 20),
                            title: Text(book['title'] ?? 'Untitled'),
                            subtitle: Text('Author: ${book['author'] ?? 'Unknown'}'),
                            dense: true,
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    final memberTypes = <String, int>{};
    for (var member in _members) {
      final type = member['member_type'] ?? 'Unknown';
      memberTypes[type] = (memberTypes[type] ?? 0) + 1;
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: warningColor),
                const SizedBox(width: 8),
                const Text(
                  'Members by Type',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_members.length} total members',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            memberTypes.isEmpty
                ? const Text('No members found')
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: memberTypes.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: warningColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(
                            color: warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}