FROM gcc:13 AS build

ARG APP_VERSION=1

WORKDIR /app

COPY src/app_v${APP_VERSION}.cpp app.cpp
COPY test/test.cpp test.cpp

RUN g++ -std=c++17 -O2 app.cpp test.cpp -o test_runner

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./test_runner"]
