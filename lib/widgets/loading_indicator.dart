import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final String? message;

  const CustomLoadingIndicator({this.message, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
          if (message != null) ...[
            SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetryWidget({
    required this.message,
    required this.onRetry,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }
}