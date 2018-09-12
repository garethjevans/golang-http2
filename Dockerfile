FROM scratch
EXPOSE 8080
ENTRYPOINT ["/golang-http2"]
COPY ./bin/ /