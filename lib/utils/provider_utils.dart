import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

T getProvider<T>(WidgetRef ref, StateProvider<T> provider) {
  return ref.watch(provider);
}
