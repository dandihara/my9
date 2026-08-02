import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/stadium_shell.dart';
import 'auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _rememberAccountKey = 'remember_account';
  static const _rememberedUsernameKey = 'remembered_username';

  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _rememberAccount = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreRememberedAccount();
  }

  Future<void> _restoreRememberedAccount() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final rememberAccount = preferences.getBool(_rememberAccountKey) ?? false;
      if (!mounted) return;
      setState(() {
        _rememberAccount = rememberAccount;
        if (rememberAccount) {
          _username.text = preferences.getString(_rememberedUsernameKey) ?? '';
        }
      });
    } on MissingPluginException {
      // Platform storage is unavailable in lightweight widget test hosts.
    }
  }

  Future<void> _saveRememberedAccount(String username) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_rememberAccountKey, _rememberAccount);
    if (_rememberAccount) {
      await preferences.setString(_rememberedUsernameKey, username);
    } else {
      await preferences.remove(_rememberedUsernameKey);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = '아이디와 비밀번호를 모두 입력해 주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final username = _username.text.trim();
      await AuthController.instance.login(username, _password.text);
      await _saveRememberedAccount(username);
    } on DioException catch (error) {
      setState(() => _error =
          error.response?.data?['detail']?.toString() ?? '서버 연결에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 760),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 28 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _GateBadge(),
                    const SizedBox(height: 8),
                    Image.asset(
                      'assets/login_hero.png',
                      height: 230,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '야구장의 모든 순간을\nMY9에 모아보세요',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '경기 일정부터 직관 추억, 선수 기록과 WPA까지\n나만의 야구 시즌을 한곳에서 즐겨요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        height: 1.55,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    StadiumTicket(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: AppColors.leaf,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.confirmation_number_rounded,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SEASON PASS',
                                      style: TextStyle(
                                        color: AppColors.coral,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      'MY9 입장하기',
                                      style: TextStyle(
                                        fontFamily: 'Jua',
                                        color: AppColors.ink,
                                        fontSize: 21,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.stadium_rounded,
                                  color: AppColors.forest),
                            ],
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _username,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: '아이디',
                              hintText: '응원 준비 완료!',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _password,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitting ? null : _login(),
                            decoration: InputDecoration(
                              labelText: '비밀번호',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                tooltip:
                                    _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                              ),
                            ),
                          ),
                          CheckboxListTile(
                            value: _rememberAccount,
                            onChanged: _submitting
                                ? null
                                : (value) => setState(
                                      () => _rememberAccount = value ?? false,
                                    ),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            title: const Text(
                              '계정 기억하기',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            child: _error == null
                                ? const SizedBox(height: 16)
                                : Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.coral.withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.coral,
                                          size: 19,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
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
                                    ),
                                  ),
                          ),
                          FilledButton.icon(
                            onPressed: _submitting ? null : _login,
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
                            label: Text(_submitting ? '입장 확인 중...' : '야구장 입장'),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => context.go('/signup'),
                            child: const Text('첫 방문이라면 무료 시즌권 만들기'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GateBadge extends StatelessWidget {
  const _GateBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ScoreboardLight(color: AppColors.coral),
            SizedBox(width: 5),
            _ScoreboardLight(color: AppColors.butter),
            SizedBox(width: 5),
            _ScoreboardLight(color: AppColors.leaf),
            SizedBox(width: 9),
            Icon(Icons.sports_baseball_rounded,
                color: AppColors.butter, size: 17),
            SizedBox(width: 7),
            Text(
              'PLAY BALL · MY9',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreboardLight extends StatelessWidget {
  const _ScoreboardLight({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .55),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}
