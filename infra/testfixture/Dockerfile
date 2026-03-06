FROM mcr.microsoft.com/dotnet/sdk@sha256:7ba12a329980dad8291cc7339ad073a8666ed949a78138eb8543a8cc8ccaa0de AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /out --no-restore

FROM mcr.microsoft.com/dotnet/aspnet@sha256:9f5100cdf26f7679ccf40dba48af9062a43e5ba0b243e80b324e8591f247b092
WORKDIR /app
COPY --from=build /out .
EXPOSE 8080
ENTRYPOINT ["dotnet", "/app/testapp.dll"]