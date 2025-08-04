import 'package:flutter/material.dart';
import '../page/settings/settings_view_model.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback? onDismiss;

  const SettingsView({super.key, this.onDismiss});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: TextButton(
          onPressed: () {
            _viewModel.commit();
            widget.onDismiss?.call();
            // TODO: Validate settings before dismissing
            // TODO: Show validation errors
            // TODO: Handle settings save errors
          },
          child: const Text(
            'Done',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          return ListView(
            children: [
              // Simple Push Server section
              _buildSection(
                title: 'Simple Push Server',
                children: [
                  _buildTextField(
                    'Server Address',
                    _viewModel.settings.pushManagerSettings.host,
                    (value) {
                      _viewModel.settings.pushManagerSettings.host = value;
                      _viewModel.commit();
                      // TODO: Validate server address format
                      // TODO: Test server connectivity
                    },
                  ),
                ],
              ),

              // Local Push Connectivity section
              _buildSection(
                title: 'Local Push Connectivity',
                footer:
                    'The NEAppPushProvider will remain active and receive incoming calls and messages while this device is on a configured cellular, Wi-Fi, or Ethernet network.',
                children: [
                  ListTile(
                    title: const Text('Cellular'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCellularSettings(),
                  ),
                  ListTile(
                    title: const Text('Wi-Fi'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showWiFiSettings(),
                  ),
                  SwitchListTile(
                    title: const Text('Runs on Ethernet'),
                    value: _viewModel.matchEthernet,
                    onChanged: (value) {
                      _viewModel.matchEthernet = value;
                      _viewModel.commit();
                      // TODO: Handle ethernet setting changes
                      // TODO: Update network configuration
                    },
                  ),
                  ListTile(
                    title: const Text('Active'),
                    trailing: Text(
                      _viewModel.isAppPushManagerActive ? 'Yes' : 'No',
                    ),
                    // TODO: Show push manager status details
                    // TODO: Handle push manager activation/deactivation
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? footer,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              footer,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          // TODO: Add input validation
          // TODO: Add field-specific validation
        ),
        controller: TextEditingController(text: value),
        onChanged: onChanged,
        // TODO: Add keyboard type validation
        // TODO: Add input format validation
      ),
    );
  }

  void _showCellularSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _CellularSettingsView(viewModel: _viewModel),
      ),
    );
  }

  void _showWiFiSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _WiFiSettingsView(viewModel: _viewModel),
      ),
    );
  }
}

class _CellularSettingsView extends StatelessWidget {
  final SettingsViewModel viewModel;

  const _CellularSettingsView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cellular'),
        actions: [
          TextButton(
            onPressed: () {
              viewModel.reset(SettingsGroup.cellular);
              // TODO: Show reset confirmation
              // TODO: Handle reset errors
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: _buildSection(
        title: 'Carrier',
        footer:
            'This device must be supervised to run Local Push Connectivity on a cellular network, unless the cellular network is Band 48 CBRS. The Tracking Area Code is only required on Band 48 CBRS networks.',
        children: [
          _buildTextField(
            'Mobile Country Code',
            viewModel.settings.pushManagerSettings.mobileCountryCode,
            (value) {
              viewModel.settings.pushManagerSettings.mobileCountryCode = value;
              viewModel.commit();
              // TODO: Validate mobile country code format
            },
          ),
          _buildTextField(
            'Mobile Network Code',
            viewModel.settings.pushManagerSettings.mobileNetworkCode,
            (value) {
              viewModel.settings.pushManagerSettings.mobileNetworkCode = value;
              viewModel.commit();
              // TODO: Validate mobile network code format
            },
          ),
          _buildTextField(
            'Tracking Area Code (optional)',
            viewModel.settings.pushManagerSettings.trackingAreaCode,
            (value) {
              viewModel.settings.pushManagerSettings.trackingAreaCode = value;
              viewModel.commit();
              // TODO: Validate tracking area code format
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? footer,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              footer,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          // TODO: Add field-specific validation
        ),
        controller: TextEditingController(text: value),
        onChanged: onChanged,
        // TODO: Add numeric keyboard for codes
        // TODO: Add input format validation
      ),
    );
  }
}

class _WiFiSettingsView extends StatelessWidget {
  final SettingsViewModel viewModel;

  const _WiFiSettingsView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi'),
        actions: [
          TextButton(
            onPressed: () {
              viewModel.reset(SettingsGroup.wifi);
              // TODO: Show reset confirmation
              // TODO: Handle reset errors
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: _buildSection(
        title: 'Network',
        children: [
          _buildTextField('SSID', viewModel.settings.pushManagerSettings.ssid, (
            value,
          ) {
            viewModel.settings.pushManagerSettings.ssid = value;
            viewModel.commit();
            // TODO: Validate SSID format
            // TODO: Test Wi-Fi connectivity
          }),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? footer,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              footer,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          // TODO: Add SSID validation
        ),
        controller: TextEditingController(text: value),
        onChanged: onChanged,
        // TODO: Add Wi-Fi keyboard
        // TODO: Add SSID format validation
      ),
    );
  }
}
