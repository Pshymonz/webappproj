Build and Run
docker compose build
docker compose up -d

Access Services
Jenkins: http://localhost:8080
docker exec devops-toolbox cat /var/lib/jenkins/secrets/initialAdminPassword

Prometheus: http://localhost:9090

https://github.com/dotnet/eShop.git

dotnet new sln -n WebSolution

git remote add origin https://github.com/Pshymonz/webappsoultion.git

Make sure you configure your "user.name" and "user.email" in git.

git config --global user.name "Simon Teff"
git config --global user.email "simon.teff@btinternet.com"
