# Kisi PubSub

This repo uses google pubsub to handle active job enqeue and processes the jobs. It stores basic stats in a database table named `worker_stats`.

## Setup
Clone the repo from github and use rails standard setup to setup the project. Make sure that you have setup the `GOOGLE_APPLICATION_CREDENTIALS`. You can use this comamnd:

`export GOOGLE_APPLICATION_CREDENTIALS="/path/to/the/json/file"`

Also disable spring:
`export DISABLE_SPRING=true`

## Running Backend Job Server
Use this command to run the backend job server:
`./bin/pubsub`

## Running A Test Job
I have create a job to test the google pubsub, you can use `MessageJob` calss for testing. First argument can be a string and second argument can be used to raise an error by passing a `true` value.
