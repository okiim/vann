import 'package:flutter/material.dart';
import 'books_page.dart';
import 'members_page.dart';
import 'borrowings_page.dart';
import 'categories_page.dart';
import 'summary_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    this.currentSection = 'Dashboard',
  });

  final String currentSection;
  static const Color primaryColor = Color(0xFF1976D2);

  void _navigateToSection(BuildContext context, String section) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardPage(currentSection: section),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.library_books, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Library Management System",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Section: $currentSection',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: _buildNavigationDrawer(context),
      body: _getCurrentSectionWidget(),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.library_books, size: 60, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'LIBRARY ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, 'Dashboard', Icons.dashboard, 'Dashboard'),
          _buildDrawerItem(context, 'Categories', Icons.category, 'Categories'),
          _buildDrawerItem(context, 'Books', Icons.book, 'Books'),
          _buildDrawerItem(context, 'Members', Icons.people, 'Members'),
          _buildDrawerItem(context, 'Borrowings', Icons.library_add, 'Borrowings'),
          _buildDrawerItem(context, 'Summary', Icons.analytics, 'Summary'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, String section) {
    final isActive = currentSection == section;
    
    return ListTile(
      leading: Icon(icon, color: isActive ? primaryColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? primaryColor : Colors.black,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _navigateToSection(context, section);
      },
    );
  }

  Widget _getCurrentSectionWidget() {
    switch (currentSection) {
      case 'Categories':
        return const CategoriesPage();
      case 'Books':
        return const BooksPage();
      case 'Members':
        return const MembersPage();
      case 'Borrowings':
        return const BorrowingsPage();
      case 'Summary':
        return const SummaryPage();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return Builder(
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Library Management System',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Welcome to the Administrative Dashboard',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _buildDashboardCard(context, 'Categories', 'Manage book categories', Icons.category, 'Categories'),
                _buildDashboardCard(context, 'Books', 'Manage library books', Icons.book, 'Books'),
                _buildDashboardCard(context, 'Members', 'Manage library members', Icons.people, 'Members'),
                _buildDashboardCard(context, 'Borrowings', 'Track book borrowings', Icons.library_add, 'Borrowings'),
                _buildDashboardCard(context, 'Summary', 'View system overview', Icons.analytics, 'Summary'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, String description, IconData icon, String section) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _navigateToSection(context, section),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: primaryColor),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}