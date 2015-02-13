# api-raml
Tools involved reading RAML files.  For example, generation of api proxy files and processing Covisint RAML extensions.

#Usage as a plugin
  raml generation tool is a maven plugin. Sample plugin configuration 
    
    <pre><code><plugin>
      <groupId>com.covisint.raml</groupId>
      <artifactId>generate-raml</artifactId>
      <version>1.0-SNAPSHOT</version>
      <executions>
        <execution>
          <phase>package</phase>
          <goals>
            <goal>generate-raml</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
    </code></pre>
#Build and run
  <code> mvn clean install 
  mvn com.covisint.raml:generate-raml:1.0-SNAPSHOT:generate-raml </code>
