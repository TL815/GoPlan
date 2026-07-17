import 'package:flutter/widgets.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatch_result.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';

import 'ui_action_presentation_coordinator.dart';

class UiActionResponseListener extends StatefulWidget {
  const UiActionResponseListener({
    super.key,
    required this.response,
    required this.coordinator,
    required this.child,
    this.onResult,
  });

  final AssistantResponse? response;
  final UiActionPresentationCoordinator coordinator;
  final Widget child;
  final ValueChanged<UiActionDispatchResult>? onResult;

  @override
  State<UiActionResponseListener> createState() =>
      _UiActionResponseListenerState();
}

class _UiActionResponseListenerState extends State<UiActionResponseListener> {
  @override
  void initState() {
    super.initState();
    _schedule(widget.response);
  }

  @override
  void didUpdateWidget(covariant UiActionResponseListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.response, widget.response)) {
      _schedule(widget.response);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _schedule(AssistantResponse? response) {
    if (response == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final result = await widget.coordinator.handleResponse(response);
      if (!mounted || result == null) return;
      widget.onResult?.call(result);
    });
  }
}
