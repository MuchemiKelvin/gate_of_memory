import 'package:flutter/material.dart';
import '../models/memorial.dart';
import '../models/category.dart';
import '../services/memorial_service.dart';
import '../services/database_init_service.dart';
import 'memorial_detail_screen.dart';
import '../widgets/memorial_card.dart';
import '../services/sync_service.dart';
import '../services/app_startup_service.dart';
import 'memorial_details_page.dart';

class MemorialDashboardScreen extends StatefulWidget {
  const MemorialDashboardScreen({super.key});

  @override
  State<MemorialDashboardScreen> createState() => _MemorialDashboardScreenState();
}

class _MemorialDashboardScreenState extends State<MemorialDashboardScreen> {
  final MemorialService _memorialService = MemorialService();
  final DatabaseInitService _dbInitService = DatabaseInitService();
  final SyncService _syncService = SyncService.instance;
  
  List<Memorial> _memorials = [];
  List<Category> _categories = [];
  List<Memorial> _filteredMemorials = [];
  Category? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isInitializing = false;
  bool _isSyncing = false;
  String _syncStatus = 'Ready';
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    // Start initialization in background without blocking UI
    _initializeDataInBackground();
    _loadSyncStatus();
  }

  Future<void> _initializeDataInBackground() async {
    // Don't show initialization screen, just start loading data
    try {
      print('Starting background database initialization...');
      
      // Initialize database if needed (in background)
      await _dbInitService.initializeDatabase();
      print('Background database initialization completed successfully');
      
      // Load data (in background)
      await _loadData();
      print('Background data loading completed successfully');
      
    } catch (e) {
      print('Background initialization error: $e');
      
      // Show error dialog only if user tries to interact
      if (mounted) {
        // Don't show error dialog immediately, just log it
        // User will see the error when they try to use features
        print('Database initialization failed: $e');
        
        // Set loading to false so user can see the empty state
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  Future<void> _loadSyncStatus() async {
    try {
      final lastSync = _syncService.lastSyncAttempt;
      final isSyncing = _syncService.isSyncing;
      
      setState(() {
        _lastSyncTime = lastSync;
        _isSyncing = isSyncing;
        _syncStatus = isSyncing ? 'Syncing...' : 'Ready';
      });
    } catch (e) {
      print('Error loading sync status: $e');
    }
  }

  Future<void> _performManualSync() async {
    try {
      setState(() {
        _isSyncing = true;
        _syncStatus = 'Starting sync...';
      });

      print('Manual sync triggered by user');
      
      // Perform template sync
      final syncSuccess = await _syncService.syncTemplates();
      
      if (syncSuccess) {
        setState(() {
          _syncStatus = 'Sync completed successfully';
          _lastSyncTime = DateTime.now();
        });
        
        // Reload memorials to get any updates
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _syncStatus = 'Sync failed';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error during manual sync: $e');
      setState(() {
        _syncStatus = 'Sync error';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
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
                    const SnackBar(content: Text('Database refreshed successfully.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Refresh failed: $e')),
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
            child: const Text('Refresh DB'),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
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
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                final dbInitService = DatabaseInitService();
                await dbInitService.forceReseed();
                _loadData(); // Reload data after re-seeding
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database refreshed successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error refreshing: $e')),
                );
              }
            },
            tooltip: 'Refresh Database (Debug)',
          ),

          // 🔄 NEW: Sync status indicator and manual sync button
          _buildSyncStatusIndicator(),
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
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading memorials...'),
                      SizedBox(height: 8),
                      Text(
                        'This may take a moment on first launch',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : _memorials.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No memorials available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This might be due to a database issue',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try refreshing the database to load memorials',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _attemptDatabaseRepair,
                                icon: const Icon(Icons.build),
                                label: const Text('Auto Repair'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final dbInitService = DatabaseInitService();
                                    await dbInitService.forceReseed();
                                    _loadData(); // Reload data after re-seeding
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Database refreshed successfully!')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error refreshing: $e')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
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

  /// 🔄 NEW: Build sync status indicator in app bar
  Widget _buildSyncStatusIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sync status icon
        Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            _isSyncing ? Icons.sync : Icons.sync_disabled,
            color: _isSyncing ? Colors.blue : Colors.grey,
            size: 20,
          ),
        ),
        
        // Manual sync button
        if (!_isSyncing)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _performManualSync,
            tooltip: 'Manual Sync',
          ),
      ],
    );
  }

  /// 🔄 NEW: Build sync status banner
  Widget _buildSyncStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getSyncStatusColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            _getSyncStatusIcon(),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _syncStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (_lastSyncTime != null)
                  Text(
                    'Last sync: ${_getTimeAgo(_lastSyncTime)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (_isSyncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Color _getSyncStatusColor() {
    if (_isSyncing) return Colors.blue;
    if (_syncStatus.contains('failed') || _syncStatus.contains('error')) return Colors.red;
    if (_syncStatus.contains('completed')) return Colors.green;
    return Colors.grey;
  }

  IconData _getSyncStatusIcon() {
    if (_isSyncing) return Icons.sync;
    if (_syncStatus.contains('failed') || _syncStatus.contains('error')) return Icons.error;
    if (_syncStatus.contains('completed')) return Icons.check_circle;
    return Icons.info;
  }

  Future<void> _attemptDatabaseRepair() async {
    try {
      print('Attempting automatic database repair...');
      
      setState(() {
        _isLoading = true;
      });
      
      // Try to force re-seed the database
      await _dbInitService.forceReseed();
      
      // Reload data
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database refreshed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      print('Database repair failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database repair failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 