import 'package:flutter/material.dart';
import '../models/memorial.dart';
import '../models/category.dart';
import '../services/memorial_service.dart';
import '../services/database_init_service.dart';
import 'memorial_detail_screen.dart';
import '../widgets/memorial_card.dart';

class MemorialDashboardScreen extends StatefulWidget {
  const MemorialDashboardScreen({super.key});

  @override
  State<MemorialDashboardScreen> createState() => _MemorialDashboardScreenState();
}

class _MemorialDashboardScreenState extends State<MemorialDashboardScreen> {
  final MemorialService _memorialService = MemorialService();
  final DatabaseInitService _dbInitService = DatabaseInitService();
  
  List<Memorial> _memorials = [];
  List<Category> _categories = [];
  List<Memorial> _filteredMemorials = [];
  Category? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // Initialize database if needed
      await _dbInitService.initializeDatabase();
      
      // Load data
      await _loadData();
    } catch (e) {
      _showErrorDialog('Database Error', 'Failed to initialize database: $e');
    } finally {
      setState(() {
        _isInitializing = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading data...');
      
      // Load categories
      final categories = await _memorialService.getAllCategories();
      print('Loaded ${categories.length} categories');
      
      // Load memorials
      final memorials = await _memorialService.getAllMemorials();
      print('Loaded ${memorials.length} memorials');
      
      setState(() {
        _categories = categories;
        _memorials = memorials;
        _filteredMemorials = memorials;
        _isLoading = false;
      });
      
      print('Data loading completed. Memorials: ${_memorials.length}, Filtered: ${_filteredMemorials.length}');
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, int> _getCategoryCounts() {
    final counts = <String, int>{};
    for (final category in _categories) {
      counts[category.name] = _memorials.where((m) => m.category == category.name).length;
    }
    return counts;
  }

  void _filterMemorials() {
    setState(() {
      _filteredMemorials = _memorials.where((memorial) {
        // Category filter
        if (_selectedCategory != null && memorial.category != _selectedCategory!.name) {
          return false;
        }
        
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return memorial.name.toLowerCase().contains(query) ||
                 memorial.description.toLowerCase().contains(query) ||
                 memorial.category.toLowerCase().contains(query) ||
                 memorial.qrCode.toLowerCase().contains(query);
        }
        
        return true;
      }).toList();
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                _isLoading = true;
              });
              try {
                await _dbInitService.forceReseed();
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Database re-seeded successfully.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Re-seed failed: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Reseed DB'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kardiverse Gallery'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Debug button for testing
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              try {
                final dbInitService = DatabaseInitService();
                await dbInitService.forceReseed();
                _loadData(); // Reload data after re-seeding
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database re-seeded successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error re-seeding: $e')),
                );
              }
            },
            tooltip: 'Re-seed Database (Debug)',
          ),
          // Database info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () async {
              try {
                await _showDatabaseInfo();
              } catch (e) {
                _showErrorDialog('Database Error', 'Failed to get database info: $e');
              }
            },
            tooltip: 'Database Info',
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing database...'),
                ],
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildSearchAndFilterSection(),
                    _buildStatisticsSection(),
                    Expanded(
                      child: _buildMemorialsGrid(),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add new memorial screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add new memorial feature coming soon!')),
          );
        },
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Add New Memorial',
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search memorials...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        _filterMemorials();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterMemorials();
            },
          ),
          const SizedBox(height: 12),
          // Category filter chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1, // +1 for "All" option
              itemBuilder: (context, index) {
                if (index == 0) {
                  final allCount = _memorials.length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('All ($allCount)'),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = null;
                        });
                        _filterMemorials();
                      },
                    ),
                  );
                }
                
                final category = _categories[index - 1];
                final categoryCount = _memorials.where((m) => m.category == category.name).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${category.name} ($categoryCount)'),
                    selected: _selectedCategory?.id == category.id,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                      _filterMemorials();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final categoryCounts = _getCategoryCounts();
    final totalMemorials = _memorials.length;
    final filteredCount = _filteredMemorials.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                '$filteredCount of $totalMemorials memorial${totalMemorials != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_selectedCategory != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Filtered by: ${_selectedCategory!.name}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (categoryCounts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: categoryCounts.entries.map((entry) {
                final category = _categories.firstWhere((c) => c.name == entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category.name).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getCategoryColor(category.name).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      color: _getCategoryColor(category.name),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'memorial':
        return const Color(0xFF7BB6E7);
      case 'celebration':
        return const Color(0xFF4CAF50);
      case 'tribute':
        return const Color(0xFFFF9800);
      case 'historical':
        return const Color(0xFF9C27B0);
      default:
        return Colors.blue;
    }
  }

  Widget _buildMemorialsGrid() {
    if (_filteredMemorials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != null
                  ? 'No memorials found matching your criteria'
                  : 'No memorials available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedCategory != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = null;
                  });
                  _filterMemorials();
                },
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredMemorials.length,
      itemBuilder: (context, index) {
        final memorial = _filteredMemorials[index];
        return MemorialCard(
          memorial: memorial,
          onTap: () => _navigateToMemorialDetail(memorial),
        );
      },
    );
  }

  void _navigateToMemorialDetail(Memorial memorial) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemorialDetailScreen(memorial: memorial),
      ),
    ).then((_) {
      // Refresh the memorial list when returning from detail screen
      _loadData();
    });
  }

  Future<void> _showDatabaseInfo() async {
    try {
      final stats = await _dbInitService.getDatabaseStatistics();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Database Information'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('Version', '${stats['databaseVersion']}'),
                _buildInfoRow('Total Memorials', '${stats['totalMemorials']}'),
                _buildInfoRow('Total Categories', '${stats['totalCategories']}'),
                _buildInfoRow('Total Media', '${stats['totalMedia']}'),
                const Divider(),
                _buildInfoRow('Categories Table', '${stats['tableCounts']['categories']}'),
                _buildInfoRow('Memorials Table', '${stats['tableCounts']['memorials']}'),
                _buildInfoRow('Media Table', '${stats['tableCounts']['media']}'),
                _buildInfoRow('Sync Log Table', '${stats['tableCounts']['sync_log']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetDatabase();
              },
              child: const Text('Reset DB'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('Error', 'Failed to get database info: $e');
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _resetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database'),
        content: const Text(
          'This will delete all data and reinitialize the database. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _dbInitService.resetDatabase();
        await _loadData();
      } catch (e) {
        _showErrorDialog('Reset Error', 'Failed to reset database: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 