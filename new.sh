#!/bin/sh

currentTime=`date "+%Y-%m-%d-%H-%M-%S"`
fileName=${currentTime}.md
hugo new posts/${fileName} && code content/posts/${fileName}

