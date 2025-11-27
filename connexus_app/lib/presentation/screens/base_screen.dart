import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Base widget for all screens in the app
abstract class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key}) : super(key: key);
}

abstract class BaseScreenState<T extends BaseScreen> extends State<T> {
  /// Override to set custom status bar appearance
  SystemUiOverlayStyle get systemUiOverlayStyle => SystemUiOverlayStyle.dark;

  /// Override to set screen background color
  Color get backgroundColor => Colors.white;

  /// Override to handle back button press
  Future<bool> onWillPop() async => true;

  /// Override to enable safe area
  bool get useSafeArea => true;

  /// Override to show app bar
  bool get showAppBar => true;

  /// Override to set app bar title
  String get appBarTitle => '';

  /// Override to add app bar actions
  List<Widget> get appBarActions => [];

  /// Build the main content of the screen
  Widget buildContent(BuildContext context);

  @override
  void initState() {
    super.initState();
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: showAppBar ? _buildAppBar() : null,
        body: useSafeArea
            ? SafeArea(child: buildContent(context))
            : buildContent(context),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (!showAppBar) return null;

    return AppBar(
      title: Text(appBarTitle),
      actions: appBarActions,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: systemUiOverlayStyle,
    );
  }

  /// Show a snackbar with a message
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a loading dialog
  void showLoadingDialog({String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 48),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(message),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog
  void hideLoadingDialog() {
    Navigator.of(context).pop();
  }
}
