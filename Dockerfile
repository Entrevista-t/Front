# Etapa de build 
FROM ghcr.io/cirruslabs/flutter:3.27.1 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG API_URL
RUN flutter build web --release --no-tree-shake-icons --dart-define=API_URL=${API_URL}

# Etapa runtime
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80