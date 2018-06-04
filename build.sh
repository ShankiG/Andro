docker build . -t jenkins/android \
&& docker tag jenkins/android docker.dev.maaii.com/jenkins/android:26.1.1 \
&& docker push http://docker.dev.maaii.com:5000/jenkins/android:26.1.1
