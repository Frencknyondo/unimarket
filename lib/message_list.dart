import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models/user_model.dart';

class MessageListPage extends StatefulWidget {
  final User currentUser;
  final User? initialPeer;

  const MessageListPage({
    super.key,
    required this.currentUser,
    this.initialPeer,
  });

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final _messageService = _MessageService();
  String _searchQuery = '';
  bool _openedInitialPeer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageService.setPresence(userId: widget.currentUser.uid, isOnline: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isOnline = state == AppLifecycleState.resumed;
    _messageService.setPresence(
      userId: widget.currentUser.uid,
      isOnline: isOnline,
    );
  }

  Future<void> _openInitialPeerIfNeeded() async {
    if (_openedInitialPeer || widget.initialPeer == null) return;
    _openedInitialPeer = true;
    final chat = await _messageService.ensureChat(
      currentUser: widget.currentUser,
      peerUser: widget.initialPeer!,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationPage(
          currentUser: widget.currentUser,
          peerUser: widget.initialPeer!,
          chatId: chat.id,
        ),
      ),
    );
  }

  String _chatPeerName(_ChatThread thread) {
    final peer = thread.participantNames.entries.firstWhere(
      (entry) => entry.key != widget.currentUser.uid,
      orElse: () => const MapEntry('', 'Unknown user'),
    );
    return peer.value.trim().isEmpty ? 'Unknown user' : peer.value;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialPeerIfNeeded();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FF),
        surfaceTintColor: const Color(0xFFF3F6FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F285C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF1F285C),
            fontWeight: FontWeight.w800,
            fontSize: 26,
          ),
        ),
      ),
      body: StreamBuilder<List<_ChatThread>>(
        stream: _messageService.chatThreadsStream(widget.currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _MessageStateCard(
              title: 'Messages unavailable',
              subtitle: 'Failed to load your conversations right now.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allThreads = snapshot.data ?? const <_ChatThread>[];
          final filteredThreads = allThreads.where((thread) {
            final peerName = _chatPeerName(thread).toLowerCase();
            return peerName.contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F172A),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.search_rounded, color: Color(0xFF7B87B7)),
                      hintText: 'Search conversations',
                      hintStyle: TextStyle(color: Color(0xFF98A2C6)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredThreads.isEmpty
                    ? _MessageStateCard(
                        title: allThreads.isEmpty
                            ? 'No conversations yet'
                            : 'No matching chats',
                        subtitle: allThreads.isEmpty
                            ? 'Once you message a seller or buyer, your chats will appear here in real time.'
                            : 'Try another name from your chat history.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                        itemCount: filteredThreads.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final thread = filteredThreads[index];
                          final peerId = thread.peerIdFor(widget.currentUser.uid);
                          final peerName = _chatPeerName(thread);

                          return StreamBuilder<User?>(
                            stream: _messageService.userStream(peerId),
                            builder: (context, userSnapshot) {
                              final peerUser = userSnapshot.data;
                              final displayUser = peerUser ??
                                  User(
                                    uid: peerId,
                                    registrationNo: '',
                                    email: '',
                                    fullName: peerName,
                                    password: '',
                                    role: 'student',
                                    createdAt: DateTime.now(),
                                  );

                              return _ConversationTile(
                                thread: thread,
                                peerUser: displayUser,
                                currentUserId: widget.currentUser.uid,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChatConversationPage(
                                        currentUser: widget.currentUser,
                                        peerUser: displayUser,
                                        chatId: thread.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChatConversationPage extends StatefulWidget {
  final User currentUser;
  final User peerUser;
  final String chatId;

  const ChatConversationPage({
    super.key,
    required this.currentUser,
    required this.peerUser,
    required this.chatId,
  });

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _messageService = _MessageService();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageService.setPresence(userId: widget.currentUser.uid, isOnline: true);
    _messageService.markChatAsRead(
      chatId: widget.chatId,
      currentUserId: widget.currentUser.uid,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isOnline = state == AppLifecycleState.resumed;
    _messageService.setPresence(
      userId: widget.currentUser.uid,
      isOnline: isOnline,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _messageService.sendMessage(
        chatId: widget.chatId,
        sender: widget.currentUser,
        receiver: widget.peerUser,
        text: text,
      );
      _messageController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FF),
        surfaceTintColor: const Color(0xFFF3F6FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F285C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: StreamBuilder<User?>(
          stream: _messageService.userStream(widget.peerUser.uid),
          builder: (context, snapshot) {
            final peer = snapshot.data ?? widget.peerUser;
            final presence = _PresenceInfo.fromUser(peer);

            return Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFE0E8FF),
                      backgroundImage: NetworkImage(
                        'https://api.dicebear.com/7.x/adventurer-neutral/png?seed=${Uri.encodeComponent(peer.fullName)}',
                      ),
                    ),
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: presence.isOnline
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF3F6FF), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        peer.fullName.trim().isEmpty ? 'Unknown user' : peer.fullName.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1F285C),
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        presence.label,
                        style: TextStyle(
                          color: presence.isOnline
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF7B87B7),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<_ChatMessage>>(
              stream: _messageService.messagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _MessageStateCard(
                    title: 'Chat unavailable',
                    subtitle: 'We could not load this conversation.',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? const <_ChatMessage>[];
                if (messages.isEmpty) {
                  return const _MessageStateCard(
                    title: 'Start the conversation',
                    subtitle: 'Send the first message and it will appear here instantly.',
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == widget.currentUser.uid;
                    final previous = index > 0 ? messages[index - 1] : null;
                    final showDate = previous == null ||
                        !_isSameDay(previous.createdAt, message.createdAt);

                    return Column(
                      children: [
                        if (showDate) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _formatDateLabel(message.createdAt),
                                style: const TextStyle(
                                  color: Color(0xFF7B87B7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                        Align(
                          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.74,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isMine ? const Color(0xFF4C6FFF) : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(24),
                                  topRight: const Radius.circular(24),
                                  bottomLeft: Radius.circular(isMine ? 24 : 8),
                                  bottomRight: Radius.circular(isMine ? 8 : 24),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x120F172A),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      color: isMine ? Colors.white : const Color(0xFF1E293B),
                                      fontSize: 15,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      _formatTime(message.createdAt),
                                      style: TextStyle(
                                        color: isMine
                                            ? Colors.white70
                                            : const Color(0xFF94A3B8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Write a message...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                        ),
                        minLines: 1,
                        maxLines: 5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _isSending
                              ? const Color(0xFFB7C5FF)
                              : const Color(0xFF4C6FFF),
                          shape: BoxShape.circle,
                        ),
                        child: _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _ChatThread thread;
  final User peerUser;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.thread,
    required this.peerUser,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final presence = _PresenceInfo.fromUser(peerUser);
    final unreadCount = thread.unreadCountFor(currentUserId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFDCE6FF),
                    backgroundImage: NetworkImage(
                      'https://api.dicebear.com/7.x/adventurer-neutral/png?seed=${Uri.encodeComponent(peerUser.fullName)}',
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: presence.isOnline
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            peerUser.fullName.trim().isEmpty
                                ? 'Unknown user'
                                : peerUser.fullName.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1F285C),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatThreadTime(thread.lastMessageAt),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastMessageText.trim().isEmpty
                                ? 'Tap to open conversation'
                                : thread.lastMessageText.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4C6FFF),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      presence.label,
                      style: TextStyle(
                        color: presence.isOnline
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageStateCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MessageStateCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8EEFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF4C6FFF),
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F285C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresenceInfo {
  final bool isOnline;
  final String label;

  const _PresenceInfo({
    required this.isOnline,
    required this.label,
  });

  factory _PresenceInfo.fromUser(User user) {
    final isOnline = user.isOnline;
    final lastSeen = user.lastSeenAt;

    if (isOnline) {
      return const _PresenceInfo(isOnline: true, label: 'Online now');
    }

    if (lastSeen == null) {
      return const _PresenceInfo(isOnline: false, label: 'Offline');
    }

    return _PresenceInfo(
      isOnline: false,
      label: 'Last seen ${_formatLastSeen(lastSeen)}',
    );
  }
}

class _MessageService {
  static const _usersCollection = 'unimarket_db';
  static const _chatsCollection = 'chats';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<_ChatThread>> chatThreadsStream(String userId) {
    return _firestore
        .collection(_chatsCollection)
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _ChatThread.fromFirestore(doc))
              .toList()
            ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt)),
        );
  }

  Stream<List<_ChatMessage>> messagesStream(String chatId) {
    return _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<User?> userStream(String userId) {
    if (userId.trim().isEmpty) return Stream.value(null);
    return _firestore.collection(_usersCollection).doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      return User.fromMap(data);
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> ensureChat({
    required User currentUser,
    required User peerUser,
  }) async {
    final chatId = _chatIdFor(currentUser.uid, peerUser.uid);
    final chatRef = _firestore.collection(_chatsCollection).doc(chatId);
    final snapshot = await chatRef.get();

    if (!snapshot.exists) {
      await chatRef.set({
        'participantIds': [currentUser.uid, peerUser.uid]..sort(),
        'participantNames': {
          currentUser.uid: currentUser.fullName.trim(),
          peerUser.uid: peerUser.fullName.trim(),
        },
        'participantEmails': {
          currentUser.uid: currentUser.email.trim(),
          peerUser.uid: peerUser.email.trim(),
        },
        'lastMessageText': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadCounts': {
          currentUser.uid: 0,
          peerUser.uid: 0,
        },
      });
    }

    return chatRef;
  }

  Future<void> sendMessage({
    required String chatId,
    required User sender,
    required User receiver,
    required String text,
  }) async {
    final chatRef = _firestore.collection(_chatsCollection).doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    final snapshot = await chatRef.get();
    final existingUnread = snapshot.data()?['unreadCounts'];
    final unreadCounts = existingUnread is Map<String, dynamic>
        ? Map<String, dynamic>.from(existingUnread)
        : <String, dynamic>{};
    final nextUnread = (unreadCounts[receiver.uid] as num?)?.toInt() ?? 0;

    await _firestore.runTransaction((transaction) async {
      transaction.set(messageRef, {
        'id': messageRef.id,
        'senderId': sender.uid,
        'receiverId': receiver.uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(chatRef, {
        'participantIds': [sender.uid, receiver.uid]..sort(),
        'participantNames': {
          sender.uid: sender.fullName.trim(),
          receiver.uid: receiver.fullName.trim(),
        },
        'participantEmails': {
          sender.uid: sender.email.trim(),
          receiver.uid: receiver.email.trim(),
        },
        'lastMessageText': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': sender.uid,
        'unreadCounts': {
          sender.uid: 0,
          receiver.uid: nextUnread + 1,
        },
      }, SetOptions(merge: true));
    });
  }

  Future<void> markChatAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    await _firestore.collection(_chatsCollection).doc(chatId).set({
      'unreadCounts': {currentUserId: 0},
    }, SetOptions(merge: true));
  }

  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {
    if (userId.trim().isEmpty) return;
    await _firestore.collection(_usersCollection).doc(userId).set({
      'isOnline': isOnline,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _chatIdFor(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return ids.join('_');
  }
}

class _ChatThread {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String lastMessageText;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCounts;

  const _ChatThread({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.unreadCounts,
  });

  factory _ChatThread.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawNames = data['participantNames'];
    final rawUnread = data['unreadCounts'];
    final timestamp = data['lastMessageAt'];

    return _ChatThread(
      id: doc.id,
      participantIds: (data['participantIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      participantNames: rawNames is Map<String, dynamic>
          ? rawNames.map((key, value) => MapEntry(key, '$value'))
          : const {},
      lastMessageText: (data['lastMessageText'] as String?) ?? '',
      lastMessageAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      unreadCounts: rawUnread is Map<String, dynamic>
          ? rawUnread.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0))
          : const {},
    );
  }

  String peerIdFor(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int unreadCountFor(String currentUserId) {
    return unreadCounts[currentUserId] ?? 0;
  }
}

class _ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;

  const _ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  factory _ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];

    return _ChatMessage(
      id: (data['id'] as String?) ?? doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      receiverId: (data['receiverId'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.now(),
    );
  }
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _formatDateLabel(DateTime dateTime) {
  final now = DateTime.now();
  if (_isSameDay(now, dateTime)) return 'Today';
  final yesterday = now.subtract(const Duration(days: 1));
  if (_isSameDay(yesterday, dateTime)) return 'Yesterday';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

String _formatThreadTime(DateTime dateTime) {
  final now = DateTime.now();
  if (_isSameDay(now, dateTime)) return _formatTime(dateTime);
  final diff = now.difference(dateTime);
  if (diff.inDays < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dateTime.weekday - 1];
  }
  return '${dateTime.day}/${dateTime.month}';
}

String _formatLastSeen(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} hr ago';
  if (diff.inDays < 7) return '${diff.inDays} day ago';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
