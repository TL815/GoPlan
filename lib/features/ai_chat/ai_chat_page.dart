part of '../../main.dart';

class _AiDialogBar extends StatelessWidget {
  const _AiDialogBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openAiChat(context),
        child: Container(
          height: 46,
          padding: const EdgeInsets.only(left: 12, right: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset('assets/images/ai.png', width: 38, height: 38),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '聊聊你的旅行想法',
                  style: TextStyle(color: Color(0xFF8F8F8F), fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 22, color: const Color(0xFFE7E7E7)),
              const SizedBox(width: 10),
              const Icon(
                Icons.keyboard_voice_outlined,
                color: Color(0xFF4C4C4C),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAiChat(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const _AiChatPage()));
  }
}

class _AiChatPage extends StatefulWidget {
  const _AiChatPage({
    this.launchRequest = const AiChatLaunchRequest.resumeLatestForTrip(),
  });

  final AiChatLaunchRequest launchRequest;

  @override
  State<_AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<_AiChatPage> {
  AiChatRuntime? _runtime;
  _AiChatStartupPhase _startupPhase = _AiChatStartupPhase.loading;
  String? _startupMessage;
  bool _isBootstrapping = false;
  bool _shownPersistenceError = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    final runtime = _runtime;
    if (runtime != null) {
      unawaited(runtime.dispose());
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_isBootstrapping) return;
    _isBootstrapping = true;
    setState(() {
      _startupPhase = _AiChatStartupPhase.loading;
      _startupMessage = null;
    });
    try {
      final runtime = await AiChatRuntime.createProduction(
        contextProvider: () => context,
        isMounted: () => mounted,
        launchRequest: widget.launchRequest,
        onPersistenceError: _handlePersistenceError,
      );
      if (!mounted) {
        await runtime.dispose();
        return;
      }
      setState(() {
        _runtime = runtime;
        _startupPhase = _AiChatStartupPhase.ready;
      });
    } on AiChatBootstrapException catch (error) {
      if (!mounted) return;
      setState(() {
        _startupPhase = _AiChatStartupPhase.failure;
        _startupMessage = error.type == AiChatBootstrapFailureType.notFound
            ? '未找到历史会话。'
            : '历史会话读取失败，请稍后重试。';
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _startupPhase = _AiChatStartupPhase.failure;
        _startupMessage = '历史会话读取失败，请稍后重试。';
      });
    } finally {
      _isBootstrapping = false;
    }
  }

  void _handlePersistenceError() {
    if (!mounted || _shownPersistenceError) return;
    _shownPersistenceError = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('会话暂时无法保存。')));
  }

  Future<void> _handleBack() async {
    final runtime = _runtime;
    if (runtime != null) {
      await runtime.dispose();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final runtime = _runtime;
    if (_startupPhase == _AiChatStartupPhase.ready && runtime != null) {
      return TravelAssistantChatView(
        controller: runtime.controller,
        coordinator: runtime.coordinator,
        ownsController: false,
        onBack: _handleBack,
      );
    }
    if (_startupPhase == _AiChatStartupPhase.failure) {
      return _AiChatStartupFailure(
        message: _startupMessage ?? '历史会话读取失败，请稍后重试。',
        retrying: _isBootstrapping,
        onRetry: _bootstrap,
      );
    }
    return const _AiChatStartupLoading();
  }
}

enum _AiChatStartupPhase { loading, ready, failure }

class _AiChatStartupLoading extends StatelessWidget {
  const _AiChatStartupLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F8F7),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
    );
  }
}

class _AiChatStartupFailure extends StatelessWidget {
  const _AiChatStartupFailure({
    required this.message,
    required this.retrying,
    required this.onRetry,
  });

  final String message;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(
                height: 66,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 24),
                      color: const Color(0xFF202326),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1EC),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF18C777),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF303437),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: retrying ? null : onRetry,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TravelAssistantChatView extends StatefulWidget {
  const TravelAssistantChatView({
    super.key,
    required this.controller,
    required this.coordinator,
    this.ownsController = false,
    this.onBack,
  });

  final TravelAssistantController controller;
  final UiActionPresentationCoordinator coordinator;
  final bool ownsController;
  final Future<void> Function()? onBack;

  @override
  State<TravelAssistantChatView> createState() =>
      _TravelAssistantChatViewState();
}

class _TravelAssistantChatViewState extends State<TravelAssistantChatView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _itinerarySectionKey = GlobalKey();
  final GlobalKey _budgetSectionKey = GlobalKey();
  late TravelAssistantState _assistantState;
  StreamSubscription<TravelAssistantState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _assistantState = widget.controller.state;
    _stateSubscription = widget.controller.states.listen(_handleStateChanged);
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    if (widget.ownsController) {
      widget.controller.dispose();
    }
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty || _assistantState.isSending) return;
    _inputController.clear();
    await widget.controller.sendMessage(text);
  }

  void _handleStateChanged(TravelAssistantState state) {
    if (!mounted) return;
    setState(() {
      _assistantState = state;
    });
    _scrollToBottom();
  }

  void _handleUiActionResult(UiActionDispatchResult result) {
    if (!mounted) return;
    switch (result.status) {
      case UiActionDispatchStatus.submitted:
        _scrollToBottom();
      case UiActionDispatchStatus.failed:
        if (result.failure != null &&
            widget.controller.state.lastFailure == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to complete the action.')),
          );
        }
      case UiActionDispatchStatus.unsupported:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This action is not supported yet.')),
        );
      case UiActionDispatchStatus.passive:
        _handlePassiveAction(result.action.type);
      case UiActionDispatchStatus.cancelled:
      case UiActionDispatchStatus.ignored:
      case UiActionDispatchStatus.busy:
        break;
    }
  }

  void _handlePassiveAction(UiActionType type) {
    switch (type) {
      case UiActionType.showItinerary:
        _scrollToKey(_itinerarySectionKey);
      case UiActionType.showBudget:
        _scrollToKey(_budgetSectionKey, fallback: _itinerarySectionKey);
      case UiActionType.showMap:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('地图路线将在后续版本中提供。')));
      case UiActionType.requestStartDate:
      case UiActionType.requestDateRange:
      case UiActionType.selectOption:
      case UiActionType.inputNumber:
      case UiActionType.confirm:
      case UiActionType.confirmDateConflict:
      case UiActionType.none:
      case UiActionType.unknown:
        break;
    }
  }

  void _scrollToKey(GlobalKey key, {GlobalKey? fallback}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = key.currentContext ?? fallback?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        alignment: .1,
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  void _openItineraryDetails() {
    final itinerary = _assistantState.itinerary;
    if (itinerary == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ItineraryDetailPage(
          itinerary: itinerary,
          additionalWarnings: _assistantState.warnings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return UiActionResponseListener(
      response: _assistantState.lastResponse,
      coordinator: widget.coordinator,
      onResult: _handleUiActionResult,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8F7),
        body: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                _AiChatHeader(onBack: widget.onBack),
                const _AiChatModeDivider(label: 'Live AI travel planning'),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                    children: [
                      if (_assistantState.messages.isEmpty &&
                          !_assistantState.isSending)
                        _AiChatEmptyState(onPromptSelected: _send),
                      for (final message in _assistantState.messages)
                        _AiMessageBubble(
                          key: ValueKey(message.id),
                          message: AiChatMessageAdapter.fromMessage(message),
                        ),
                      if (_assistantState.isSending)
                        const AssistantLoadingIndicator(),
                      if (_assistantState.phase ==
                              TravelAssistantPhase.failure &&
                          _assistantState.lastFailure != null)
                        AssistantFailureCard(
                          failure: _assistantState.lastFailure!,
                          retryEnabled: !_assistantState.isSending,
                          onRetry: widget.controller.retryLast,
                        ),
                      if (_assistantState.itinerary != null)
                        Padding(
                          key: _itinerarySectionKey,
                          padding: const EdgeInsets.only(top: 2, bottom: 18),
                          child: ItineraryOverviewCard(
                            itinerary: _assistantState.itinerary!,
                            additionalWarnings: _assistantState.warnings,
                            onOpenDetails: _openItineraryDetails,
                            budgetSectionKey: _budgetSectionKey,
                          ),
                        ),
                    ],
                  ),
                ),
                _AiChatInput(
                  controller: _inputController,
                  enabled: !_assistantState.isSending,
                  onSend: _send,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiChatHeader extends StatelessWidget {
  const _AiChatHeader({this.onBack});

  final Future<void> Function()? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                final handler = onBack;
                if (handler == null) {
                  Navigator.of(context).pop();
                } else {
                  unawaited(handler());
                }
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 24),
              color: const Color(0xFF202326),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'GoPlan AI 旅行规划',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF151515),
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 22),
              color: const Color(0xFF202326),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded, size: 23),
              color: const Color(0xFF202326),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiChatModeDivider extends StatelessWidget {
  const _AiChatModeDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE4E4E4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB3B3B3),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE4E4E4))),
        ],
      ),
    );
  }
}

class _AiChatEmptyState extends StatelessWidget {
  const _AiChatEmptyState({required this.onPromptSelected});

  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 18),
      child: Column(
        children: [
          const _AiOrb(size: 46),
          const SizedBox(height: 18),
          const Text(
            '告诉我你的旅行想法',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'I can help turn destination, dates, budget, and preferences into a practical trip plan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF858B8D),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _AiPromptChip(
                text: 'Western Sichuan 6 days',
                onTap: () => onPromptSelected(
                  'Plan a 6 day Western Sichuan trip from Chengdu with a comfortable pace.',
                ),
              ),
              _AiPromptChip(
                text: 'Hangzhou weekend',
                onTap: () => onPromptSelected(
                  'Plan a relaxed 2 day Hangzhou weekend with West Lake, cafes, and photo spots.',
                ),
              ),
              _AiPromptChip(
                text: 'Yunnan graduation',
                onTap: () => onPromptSelected(
                  'Plan an 8 day Yunnan graduation trip for 4 people who like food and nature.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiPromptChip extends StatelessWidget {
  const _AiPromptChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF343738),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiMessageBubble extends StatelessWidget {
  const _AiMessageBubble({super.key, required this.message});

  final AiChatMessageViewData message;

  @override
  Widget build(BuildContext context) {
    final viewData = message;
    final bubble = _AiTextBubble(message: viewData);

    if (viewData.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: bubble,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AiOrb(size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bubble],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiTextBubble extends StatelessWidget {
  const _AiTextBubble({required this.message});

  final AiChatMessageViewData message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .7,
      ),
      padding: message.isUser
          ? const EdgeInsets.symmetric(horizontal: 15, vertical: 12)
          : EdgeInsets.zero,
      decoration: message.isUser
          ? BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(13),
            )
          : null,
      child: Text(
        message.text,
        style: TextStyle(
          color: message.isUser ? Colors.white : const Color(0xFF202426),
          fontSize: 14,
          height: 1.42,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AiChatInput extends StatelessWidget {
  const _AiChatInput({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(27),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.attach_file_rounded, size: 20),
              color: const Color(0xFF4A4D50),
            ),
            Container(width: 1, height: 24, color: const Color(0xFFE8E8E8)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                enabled: enabled,
                controller: controller,
                minLines: 1,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '问我任何旅行问题...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9B9FA1),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.keyboard_voice_outlined, size: 21),
              color: const Color(0xFF4A4D50),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiOrb extends StatelessWidget {
  const _AiOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-.35, -.35),
          radius: .9,
          colors: [Color(0xFFE7FFF0), Color(0xFF6DE58E), Color(0xFF17B95A)],
          stops: [0, .48, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3317B95A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
