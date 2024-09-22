#Taking redis as base image
FROM redis

#Exposing redis default port to the Host OS
EXPOSE 6379

#Starting the redis service in the container
CMD ["redis-server"]