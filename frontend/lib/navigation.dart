import 'package:flutter/material.dart';

/// Permite navegar para o login de fora de um widget (ex.: token expirado).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Avisa telas (via [RouteAware]) quando elas voltam a ficar visíveis,
/// para recarregarem os dados (ex.: Home depois de criar uma avaliação).
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
