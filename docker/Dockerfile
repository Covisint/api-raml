FROM ubuntu
MAINTAINER Venky <venky@duh-uh.com>

RUN apt-get update \
    && apt-get install -y \
        git \
        nodejs-legacy \
        npm \
        ruby

# Install Bower and Grunt
RUN npm install --silent -g bower grunt-cli

# Install sass
RUN gem install --no-ri --no-rdoc sass

# Clone the Covisint api-console fork
RUN git clone https://github.com/venkytv/api-console.git

WORKDIR /api-console
RUN git fetch && git checkout 50a44d4e9c73b188c3ea72b671066254a69de1f8
RUN rm -rf /api-console/dist/raml

RUN npm install --silent
RUN bower install --allow-root

# api-console listens on port 9000
EXPOSE 9000

COPY ./run-api-console /api-console/
COPY ./raml.rb /api-console/
COPY ./ramlparser.rb /api-console/
COPY ./gencsv.rb /api-console/

ENTRYPOINT [ "/api-console/run-api-console" ]
CMD [ "grunt", "server" ]
