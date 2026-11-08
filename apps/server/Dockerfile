FROM dart:stable

WORKDIR /workspace

COPY <<EOF pubspec.yaml
name: rent_a_luxury_server_image
environment:
  sdk: ^3.13.0
workspace:
  - apps/server
  - packages/domain
  - packages/api_contract
  - packages/api_mapping
EOF

COPY apps/server apps/server
COPY packages/domain packages/domain
COPY packages/api_contract packages/api_contract
COPY packages/api_mapping packages/api_mapping

RUN dart pub get
RUN dart analyze apps/server

CMD ["dart", "run", "apps/server/bin/server.dart"]