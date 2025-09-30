/// GraphQL client skeleton supporting query/mutation + subscription placeholder.
/// Integrates later with NetworkingAdapter.graphQL + WebSocket adapter.
import 'dart:async';
import '../adapters/networking_adapter.dart';
import '../models/networking_models.dart';

class GraphQLRequest {
  final String endpoint;
  final String document; // query or mutation
  final Map<String, dynamic>? variables;
  final String? operationName;
  final Map<String, String>? headers;
  GraphQLRequest({
    required this.endpoint,
    required this.document,
    this.variables,
    this.operationName,
    this.headers,
  });
}

class GraphQLClient {
  GraphQLClient._();
  static GraphQLClient? _instance;
  static GraphQLClient get instance => _instance ??= GraphQLClient._();

  NetworkingAdapter? _adapter;

  void bindAdapter(NetworkingAdapter adapter) => _adapter = adapter;

  Future<GraphQLResponse> query(GraphQLRequest req) => _exec(req);
  Future<GraphQLResponse> mutate(GraphQLRequest req) => _exec(req);

  Future<GraphQLResponse> _exec(GraphQLRequest req) async {
    if (_adapter == null) {
      throw StateError('GraphQLClient: adapter not bound');
    }
    return _adapter!.graphQL(
      req.endpoint,
      req.document,
      variables: req.variables,
      headers: req.headers,
      operationName: req.operationName,
    );
  }

  /// Placeholder subscription API (will use WebSocket later).
  Stream<Map<String, dynamic>> subscribe(GraphQLRequest req) async* {
    // Emit a single mock event for now.
    yield {'event': 'subscription_mock', 'op': req.operationName};
  }
}
