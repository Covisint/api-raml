# api-raml
Tools involved reading RAML files.  For example, generation of api proxy files and processing Covisint RAML extensions.

#Usage
  raml generation tool is a maven plugin. Sample plugin configuration 
  
   <plugin>
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
