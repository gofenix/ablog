#!/bin/sh

currentTime=`date "+%Y-%m-%d-%H-%M-%S"`
fileName=${currentTime}.md
hugo new blogs/${fileName} && code content/blogs/${fileName}

