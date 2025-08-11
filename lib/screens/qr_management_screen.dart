/// QR Code Management Screen
/// 
/// This screen provides a comprehensive interface for managing QR codes,
/// including generation, viewing, and validation history.
import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/license.dart';
import '../models/template.dart';
import '../services/qr_service.dart';
import '../services/license_service.dart';
import '../services/sync_service.dart';
import '../config/api_config.dart';

class QRManagementScreen extends StatefulWidget {
  const QRManagementScreen({super.key});

  @override
  State<QRManagementScreen> createState() => _QRManagementScreenState();
}

class _QRManagementScreenState extends State<QRManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final QRService _qrService = QRService.instance;
  final LicenseService _licenseService = LicenseService.instance;
  final SyncService _syncService = SyncService.instance;
  
  // QR Code generation
  Uint8List? _generatedQRCode;
  bool _isGenerating = false;
  String _generationMessage = '';
  
  // QR Code validation
  final TextEditingController _qrInputController = TextEditingController();
  Map<String, dynamic>? _validationResult;
  bool _isValidating = false;
  
  // Cache statistics
  Map<String, dynamic> _cacheStats = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCacheStatistics();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _qrInputController.dispose();
    super.dispose();
  }
  
  /// Load cache statistics
  Future<void> _loadCacheStatistics() async {
    final stats = _qrService.getCacheStatistics();
    setState(() {
      _cacheStats = stats;
    });
  }
  
  /// Generate QR code for a license
  Future<void> _generateLicenseQRCode() async {
    setState(() {
      _isGenerating = true;
      _generationMessage = 'Generating license QR code...';
      _generatedQRCode = null;
    });
    
    try {
      // For demo purposes, create a sample license
      // In real app, this would come from user selection
      final sampleLicense = License(
        id: 1,
        code: 'KARD-${DateTime.now().millisecondsSinceEpoch}',
        templateId: 1,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final qrCode = await _qrService.generateQRCode(sampleLicense);
      
      if (qrCode != null) {
        setState(() {
          _generatedQRCode = qrCode;
          _generationMessage = 'QR code generated successfully!';
        });
        
        ApiConfig.logApiCall('QR code generated', data: {
          'license_code': sampleLicense.code,
          'qr_size': qrCode.length,
        });
      } else {
        setState(() {
          _generationMessage = 'Failed to generate QR code';
        });
      }
    } catch (e) {
      setState(() {
        _generationMessage = 'Error: ${e.toString()}';
      });
      ApiConfig.logApiError('Generate license QR code', e);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  
  /// Generate QR code for a template
  Future<void> _generateTemplateQRCode() async {
    setState(() {
      _isGenerating = true;
      _generationMessage = 'Generating template QR code...';
      _generatedQRCode = null;
    });
    
    try {
      // For demo purposes, create a sample template
      // In real app, this would come from user selection
      final sampleTemplate = Template(
        id: 1,
        name: 'Memorial Template',
        description: 'Beautiful memorial design',
        category: 'memorial',
        version: '1.0',
        fileSize: 1024 * 1024,
        fileType: 'application/pdf',
        fileUrl: 'https://example.com/template.pdf',
        status: 'active',
        syncStatus: 'synced',
        downloadCount: 0,
        viewCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final qrCode = await _qrService.generateTemplateQRCode(sampleTemplate);
      
      if (qrCode != null) {
        setState(() {
          _generatedQRCode = qrCode;
          _generationMessage = 'Template QR code generated successfully!';
        });
        
        ApiConfig.logApiCall('Template QR code generated', data: {
          'template_id': sampleTemplate.id,
          'template_name': sampleTemplate.name,
          'qr_size': qrCode.length,
        });
      } else {
        setState(() {
          _generationMessage = 'Failed to generate template QR code';
        });
      }
    } catch (e) {
      setState(() {
        _generationMessage = 'Error: ${e.toString()}';
      });
      ApiConfig.logApiError('Generate template QR code', e);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  
  /// Validate QR code
  Future<void> _validateQRCode() async {
    final qrData = _qrInputController.text.trim();
    if (qrData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter QR code data to validate')),
      );
      return;
    }
    
    setState(() {
      _isValidating = true;
      _validationResult = null;
    });
    
    try {
      final result = await _qrService.validateQRCode(qrData);
      
      setState(() {
        _validationResult = result;
      });
      
      if (result != null && result['success'] == true) {
        ApiConfig.logApiCall('QR validation successful', data: {
          'qr_data': qrData,
          'validation_method': result['validation_method'],
        });
      } else {
        ApiConfig.logApiCall('QR validation failed', data: {
          'qr_data': qrData,
          'error': result?['message'] ?? 'Unknown error',
        });
      }
    } catch (e) {
      setState(() {
        _validationResult = {
          'success': false,
          'message': 'Validation error: ${e.toString()}',
          'error_code': 'validation_error',
        };
      });
      ApiConfig.logApiError('Validate QR code', e);
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }
  
  /// Clear validation cache
  Future<void> _clearValidationCache() async {
    _qrService.clearValidationCache();
    await _loadCacheStatistics();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Validation cache cleared')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Management'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Generate', icon: Icon(Icons.qr_code)),
            Tab(text: 'Validate', icon: Icon(Icons.verified)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateTab(),
          _buildValidateTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }
  
  /// Build Generate tab
  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate QR Codes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Create QR codes for licenses and templates. These can be used for '
                    'quick access and sharing.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // License QR Code Generation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.license, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Text(
                        'License QR Code',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Generate a QR code for a license that can be scanned to activate '
                    'templates and access memorial features.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateLicenseQRCode,
                    icon: _isGenerating 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.qr_code),
                    label: Text(_isGenerating ? 'Generating...' : 'Generate License QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Template QR Code Generation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.template, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Template QR Code',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Generate a QR code for a template that can be scanned to quickly '
                    'select and apply the template to memorials.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateTemplateQRCode,
                    icon: _isGenerating 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.qr_code),
                    label: Text(_isGenerating ? 'Generating...' : 'Generate Template QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Generated QR Code Display
          if (_generatedQRCode != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Generated QR Code',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.memory(
                        _generatedQRCode!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _generationMessage,
                      style: TextStyle(
                        color: _generationMessage.contains('successfully') 
                            ? Colors.green[600] 
                            : Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Build Validate tab
  Widget _buildValidateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Validate QR Codes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter QR code data to validate it against the backend. '
                    'Offline validation is also supported using cached results.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // QR Code Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR Code Data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qrInputController,
                    decoration: InputDecoration(
                      hintText: 'Enter QR code data or scan a code...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          // TODO: Implement QR scanner integration
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('QR scanner integration coming soon')),
                          );
                        },
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isValidating ? null : _validateQRCode,
                      icon: _isValidating 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified),
                      label: Text(_isValidating ? 'Validating...' : 'Validate QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Validation Result
          if (_validationResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _validationResult!['success'] == true 
                              ? Icons.check_circle 
                              : Icons.error,
                          color: _validationResult!['success'] == true 
                              ? Colors.green[600] 
                              : Colors.red[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Validation Result',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildValidationResultDetails(_validationResult!),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Build validation result details
  Widget _buildValidationResultDetails(Map<String, dynamic> result) {
    final isSuccess = result['success'] == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSuccess ? Colors.green[200]! : Colors.red[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green[600] : Colors.red[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result['message'] ?? 'No message available',
                  style: TextStyle(
                    color: isSuccess ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        if (result['data'] != null) ...[
          const SizedBox(height: 16),
          Text(
            'Validation Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDataTable(result['data']),
        ],
        
        if (result['validation_method'] != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                result['validation_method'] == 'online' 
                    ? Icons.cloud 
                    : Icons.offline_bolt,
                color: result['validation_method'] == 'online' 
                    ? Colors.blue[600] 
                    : Colors.orange[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Validation Method: ${result['validation_method']}',
                style: TextStyle(
                  color: result['validation_method'] == 'online' 
                      ? Colors.blue[600] 
                      : Colors.orange[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        
        if (result['offline_warning'] != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result['offline_warning'],
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  /// Build data table for validation result
  Widget _buildDataTable(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: data.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    key.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value?.toString() ?? 'N/A',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  /// Build Settings tab
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR Code Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Configure QR code behavior and manage validation cache.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Cache Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Validation Cache',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCacheStatistics(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearValidationCache,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear Validation Cache'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red[600]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // QR Code Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Text(
                        'QR Code Configuration',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildConfigurationOptions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build cache statistics
  Widget _buildCacheStatistics() {
    return Column(
      children: [
        _buildStatRow('Total Entries', '${_cacheStats['total_entries'] ?? 0}'),
        _buildStatRow('Valid Entries', '${_cacheStats['valid_entries'] ?? 0}'),
        _buildStatRow('Expired Entries', '${_cacheStats['expired_entries'] ?? 0}'),
        _buildStatRow('Cache Expiry', '${_cacheStats['cache_expiry_hours'] ?? 24} hours'),
      ],
    );
  }
  
  /// Build stat row
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.blue[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build configuration options
  Widget _buildConfigurationOptions() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Enable Offline Validation'),
          subtitle: const Text('Allow QR validation without internet connection'),
          value: true, // TODO: Make this configurable
          onChanged: (value) {
            // TODO: Implement configuration persistence
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuration updated')),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Auto-Clear Expired Cache'),
          subtitle: const Text('Automatically remove expired validation results'),
          value: true, // TODO: Make this configurable
          onChanged: (value) {
            // TODO: Implement configuration persistence
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuration updated')),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Show Validation Method'),
          subtitle: const Text('Display whether validation was online or offline'),
          value: true, // TODO: Make this configurable
          onChanged: (value) {
            // TODO: Implement configuration persistence
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuration updated')),
            );
          },
        ),
      ],
    );
  }
} 