/// Template Management Screen
/// 
/// This screen provides a comprehensive interface for managing templates,
/// including viewing, downloading, and managing template versions.
import 'package:flutter/material.dart';
import '../models/template.dart';
import '../services/template_service.dart';
import '../services/sync_service.dart';
import '../services/template_storage_service.dart';
import '../config/api_config.dart';
import 'category_mapping_service.dart';

class TemplateManagementScreen extends StatefulWidget {
  const TemplateManagementScreen({super.key});

  @override
  State<TemplateManagementScreen> createState() => _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TemplateService _templateService = TemplateService.instance;
  final SyncService _syncService = SyncService.instance;
  final TemplateStorageService _storageService = TemplateStorageService.instance;
  
  // Template data
  List<Template> _templates = [];
  List<Template> _filteredTemplates = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  
  // Statistics
  Map<String, dynamic> _statistics = {};
  
  // Download progress
  final Map<int, double> _downloadProgress = {};
  final Map<int, bool> _isDownloading = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTemplates();
    _loadStatistics();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// Load templates from service
  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final templates = await _templateService.fetchTemplates();
      if (templates != null) {
        setState(() {
          _templates = templates;
          _filteredTemplates = templates;
        });
        _applyFilters();
      }
    } catch (e) {
      ApiConfig.logApiError('Load templates', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load templates: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Load template statistics
  Future<void> _loadStatistics() async {
    try {
      final stats = await _templateService.getTemplateStatistics();
      if (stats != null) {
        setState(() {
          _statistics = stats;
        });
      }
    } catch (e) {
      ApiConfig.logApiError('Load statistics', e);
    }
  }
  
  /// Apply search and category filters
  void _applyFilters() {
    List<Template> filtered = _templates;
    
    // Apply category filter
    if (_selectedCategory != 'all') {
      filtered = filtered.where((template) => 
        template.category.toLowerCase() == _selectedCategory.toLowerCase()
      ).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((template) =>
        template.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        template.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    setState(() {
      _filteredTemplates = filtered;
    });
  }
  
  /// Download template
  Future<void> _downloadTemplate(Template template) async {
    if (_isDownloading[template.id] == true) return;
    
    setState(() {
      _isDownloading[template.id] = true;
      _downloadProgress[template.id] = 0.0;
    });
    
    try {
      // Simulate download progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _downloadProgress[template.id] = i / 100;
        });
      }
      
      // Actual download
      final success = await _templateService.downloadTemplate(template.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${template.name} downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh templates to update download status
        await _loadTemplates();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${template.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ApiConfig.logApiError('Download template', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDownloading[template.id] = false;
        _downloadProgress.remove(template.id);
      });
    }
  }
  
  /// Refresh templates
  Future<void> _refreshTemplates() async {
    await _loadTemplates();
    await _loadStatistics();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Management'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTemplates,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Templates', icon: Icon(Icons.template)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplatesTab(),
          _buildCategoriesTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }
  
  /// Build Templates tab
  Widget _buildTemplatesTab() {
    return Column(
      children: [
        // Search and filter bar
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search templates...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _applyFilters();
                },
              ),
              
              const SizedBox(height: 16),
              
              // Category filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('all', 'All'),
                    ...CategoryMappingService.allBackendCategories.map((category) =>
                      _buildCategoryChip(category, category.replaceAll('-', ' ').toUpperCase())
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Templates list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredTemplates.isEmpty
                  ? const Center(
                      child: Text(
                        'No templates found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredTemplates.length,
                      itemBuilder: (context, index) {
                        final template = _filteredTemplates[index];
                        return _buildTemplateCard(template);
                      },
                    ),
        ),
      ],
    );
  }
  
  /// Build category chip
  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : 'all';
          });
          _applyFilters();
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue[200],
      ),
    );
  }
  
  /// Build template card
  Widget _buildTemplateCard(Template template) {
    final isDownloading = _isDownloading[template.id] == true;
    final downloadProgress = _downloadProgress[template.id] ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(template),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Template details
            Row(
              children: [
                _buildDetailChip(Icons.category, template.categoryDisplayName),
                const SizedBox(width: 8),
                _buildDetailChip(Icons.info, template.version),
                const SizedBox(width: 8),
                _buildDetailChip(Icons.storage, template.formattedFileSize),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sync status and actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSyncStatusRow(template),
                      if (template.lastSyncedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Last synced: ${template.timeSinceLastSync}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildActionButtons(template, isDownloading, downloadProgress),
              ],
            ),
            
            // Download progress
            if (isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: downloadProgress),
              const SizedBox(height: 8),
              Text(
                'Downloading... ${(downloadProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Build status chip
  Widget _buildStatusChip(Template template) {
    Color color;
    String text;
    
    if (template.isActive) {
      color = Colors.green;
      text = 'Active';
    } else if (template.status.toLowerCase() == 'draft') {
      color = Colors.orange;
      text = 'Draft';
    } else {
      color = Colors.grey;
      text = 'Inactive';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Build detail chip
  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build sync status row
  Widget _buildSyncStatusRow(Template template) {
    IconData icon;
    Color color;
    String text;
    
    if (template.isSynced) {
      icon = Icons.check_circle;
      color = Colors.green;
      text = 'Synced';
    } else if (template.syncStatus.toLowerCase() == 'failed') {
      icon = Icons.error;
      color = Colors.red;
      text = 'Sync Failed';
    } else {
      icon = Icons.sync;
      color = Colors.orange;
      text = 'Pending Sync';
    }
    
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  /// Build action buttons
  Widget _buildActionButtons(Template template, bool isDownloading, double downloadProgress) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Download button
        ElevatedButton.icon(
          onPressed: isDownloading ? null : () => _downloadTemplate(template),
          icon: isDownloading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: Text(isDownloading ? 'Downloading...' : 'Download'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // More options button
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'view':
                _viewTemplate(template);
                break;
              case 'versions':
                _viewTemplateVersions(template);
                break;
              case 'share':
                _shareTemplate(template);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'versions',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text('Versions'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Build Categories tab
  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Template Categories',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Browse templates by category. Each category contains different types '
                    'of templates for various memorial purposes.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Category grid
          ...CategoryMappingService.allBackendCategories.map((category) =>
            _buildCategoryCard(category)
          ),
        ],
      ),
    );
  }
  
  /// Build category card
  Widget _buildCategoryCard(String category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
          _tabController.animateTo(0); // Switch to templates tab
          _applyFilters();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: Colors.blue[600],
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.replaceAll('-', ' ').toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCategoryDescription(category),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build Statistics tab
  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overview card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Template Statistics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatisticsGrid(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Category breakdown
          if (_statistics['category_breakdown'] != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryBreakdown(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // File type breakdown
          if (_statistics['file_type_breakdown'] != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Type Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFileTypeBreakdown(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Build statistics grid
  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Templates',
          '${_statistics['total_templates'] ?? 0}',
          Icons.template,
          Colors.blue,
        ),
        _buildStatCard(
          'Active Templates',
          '${_statistics['active_templates'] ?? 0}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Synced Templates',
          '${_statistics['synced_templates'] ?? 0}',
          Icons.sync,
          Colors.orange,
        ),
        _buildStatCard(
          'Total Size',
          '${_statistics['total_file_size_formatted'] ?? '0B'}',
          Icons.storage,
          Colors.purple,
        ),
      ],
    );
  }
  
  /// Build stat card
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Build category breakdown
  Widget _buildCategoryBreakdown() {
    final breakdown = _statistics['category_breakdown'] as Map<String, dynamic>?;
    if (breakdown == null) return const SizedBox.shrink();
    
    return Column(
      children: breakdown.entries.map((entry) {
        final category = entry.key;
        final count = entry.value as int;
        final percentage = _statistics['total_templates'] > 0 
            ? (count / _statistics['total_templates'] * 100).toStringAsFixed(1)
            : '0.0';
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  category.replaceAll('-', ' ').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: _statistics['total_templates'] > 0 
                      ? count / _statistics['total_templates']
                      : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 60,
                child: Text(
                  '$count ($percentage%)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  /// Build file type breakdown
  Widget _buildFileTypeBreakdown() {
    final breakdown = _statistics['file_type_breakdown'] as Map<String, dynamic>?;
    if (breakdown == null) return const SizedBox.shrink();
    
    return Column(
      children: breakdown.entries.map((entry) {
        final fileType = entry.key;
        final count = entry.value as int;
        
        return ListTile(
          leading: Icon(_getFileTypeIcon(fileType), color: Colors.blue[600]),
          title: Text(fileType.toUpperCase()),
          trailing: Text(
            '$count',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      }).toList(),
    );
  }
  
  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'business-cards':
        return Icons.business;
      case 'greeting-cards':
        return Icons.card_giftcard;
      case 'invitations':
        return Icons.invite;
      case 'flyers':
        return Icons.article;
      case 'posters':
        return Icons.wallpaper;
      default:
        return Icons.template;
    }
  }
  
  /// Get category description
  String _getCategoryDescription(String category) {
    switch (category.toLowerCase()) {
      case 'business-cards':
        return 'Professional business card templates';
      case 'greeting-cards':
        return 'Beautiful greeting card designs';
      case 'invitations':
        return 'Elegant invitation templates';
      case 'flyers':
        return 'Informative flyer layouts';
      case 'posters':
        return 'Eye-catching poster designs';
      default:
        return 'Template category';
    }
  }
  
  /// Get file type icon
  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  /// View template
  void _viewTemplate(Template template) {
    // TODO: Implement template viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${template.name}')),
    );
  }
  
  /// View template versions
  void _viewTemplateVersions(Template template) {
    // TODO: Implement version viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing versions of ${template.name}')),
    );
  }
  
  /// Share template
  void _shareTemplate(Template template) {
    // TODO: Implement template sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${template.name}')),
    );
  }
} 