import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'connections_viewmodel.dart';

class ConnectionsView extends StatelessWidget {
  const ConnectionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ConnectionsViewModel>.reactive(
      viewModelBuilder: ConnectionsViewModel.new,
      onViewModelReady: (ConnectionsViewModel viewModel) => viewModel.initialise(),
      builder: (BuildContext context, ConnectionsViewModel viewModel, Widget? child) {
        final requests = viewModel.showPending
            ? viewModel.pendingRequests
            : viewModel.invitedRequests;

        return Scaffold(
          appBar: AppBar(title: const Text('Connections')),
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<bool>(
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Wants to connect'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('You invited'),
                    ),
                  ],
                  selected: <bool>{viewModel.showPending},
                  onSelectionChanged: (Set<bool> value) => viewModel.toggle(value.first),
                ),
              ),
              Expanded(
                child: viewModel.isBusy
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: requests.length,
                        itemBuilder: (BuildContext context, int index) {
                          final request = requests[index];
                          final user =
                              viewModel.showPending ? request.sender : request.receiver;

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(user.displayName[0].toUpperCase()),
                              ),
                              title: Text(user.displayName),
                              subtitle: Text(user.mobile),
                              trailing: FilledButton(
                                onPressed: () => viewModel.showPending
                                    ? viewModel.accept(request.id)
                                    : viewModel.cancel(request.id),
                                child: Text(viewModel.showPending ? 'Accept' : 'Undo request'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
