import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/stadium_shell.dart';
import 'auth_controller.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _nickname = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_username.text.trim().length < 3 || _password.text.length < 4) {
      setState(() => _error = '아이디는 3자, 비밀번호는 4자 이상 입력해 주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await AuthController.instance.register(
        _username.text.trim(),
        _password.text,
        _nickname.text.trim(),
      );
    } on DioException catch (error) {
      setState(() => _error =
          error.response?.data?['detail']?.toString() ?? '가입에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/login');
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('시즌권 만들기')),
        body: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 34),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/login_hero.png',
                            width: 116,
                            height: 116,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '나만의 야구 시즌\n지금 시작해요!',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  '응원팀은 가입 후 선택할 수 있어요.',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      StadiumTicket(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.local_activity_rounded,
                                    color: AppColors.coral),
                                SizedBox(width: 9),
                                Text(
                                  'ROOKIE SEASON PASS',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _username,
                              autofillHints: const [AutofillHints.newUsername],
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: '아이디',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nickname,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: '야구장 닉네임',
                                prefixIcon: Icon(Icons.badge_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  _submitting ? null : _register(),
                              decoration: InputDecoration(
                                labelText: '비밀번호',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.coral.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppColors.coral,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: _submitting ? null : _register,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.sports_baseball_rounded),
                              label:
                                  Text(_submitting ? '선수 등록 중...' : '시즌 시작하기'),
                            ),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('이미 시즌권이 있어요 · 로그인'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '가입하면 나만의 직관 기록과 메모를 안전하게 보관할 수 있어요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
