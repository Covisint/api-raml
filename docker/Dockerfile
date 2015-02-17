FROM ubuntu
MAINTAINER Venky <venky@duh-uh.com>

RUN apt-get update \
    && apt-get install -y \
        git \
        nodejs-legacy \
        npm \
        ruby

# Clone the Covisint api-console fork
RUN git clone https://github.com/venkytv/api-console.git
RUN rm -rf /api-console/dist/raml

WORKDIR /api-console

# Install Sass, Bower and Grunt
RUN gem install --no-ri --no-rdoc sass
RUN npm install --silent -g bower grunt-cli
RUN npm install --silent
RUN bower install --allow-root

# api-console listens on port 9000
EXPOSE 9000

COPY ./run-api-console /api-console/
COPY ./raml.rb /api-console/
COPY ./ramlparser.rb /api-console/
COPY ./gencsv.rb /api-console/
COPY ./release-manifest.yml /api-console/

ENTRYPOINT [ "/api-console/run-api-console" ]
CMD [ "grunt", "server" ]
