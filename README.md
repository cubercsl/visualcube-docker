# VisualCube Docker Image


### Installation Instructions

These instructions are for installing the script on your own web server by docker. If you do not have access to your own server, or would just like to try out the software, please visit:
http://cube.crider.co.uk/visualcube.php or the source repository https://github.com/Cride5/visualcube.

##### Steps
1. Clone the repository
```bash
$ https://github.com/2014CAIS01/visualcube-docker
```
2. (Optional) Edit the configuration variables `.env` file.
3. (Optional) Edit the `docker-compose.yml` if you want to change the port.
4. Deploy
```
$ docker-compose up -d --build
```
5. (Optional) Install the cron job to clean the cache every week.
```bash
$ crontab -e
```
and add a line:
```cron
0 3 * * 0 docker exec visualcube visualcube_dbprune.sh && echo $(date) "success." >> ~/visualcube.log 2>&1
```
