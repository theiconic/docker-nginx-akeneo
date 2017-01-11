# docker-nginx-akeneo
Akeneo PIM docker using Nginx

## Running Image as stand-alone
First create an image tag
```BASH
git clone https://github.com/theiconic/docker-nginx-akeneo.git
cd docker-nginx-akeneo
docker build -t theiconic/docker-nginx-akeneo . # Note the "."

```

Then create a simple run file to encapsulate all options:
```BASH
cat > run.sh <<-EOF
SOURCE_FOLDER=$1
# Run the image
exec docker run -it --rm 					   \\
    -v "\${SOURCE_FOLDER}:/var/www/pim/" 	   \\
    -v "\${PWD}/scripts:/var/www/html/scripts" \\
    -v "\${PWD}/conf:/var/www/html/conf" 	   \\
    -e "PHP_MEM_LIMIT=512"	\\
    -e "RUN_SCRIPTS=1" 		\\
    -e "PIM_DB_HOST=~~~" 	\\
    -e "PIM_DB_PORT=3306" 	\\
    -e "PIM_DB_NAME=~~~~" 	\\
    -e "PIM_DB_USER=~~~~" 	\\
    -e "PIM_DB_PASSWORD=~~~~" \\
    -e "PIM_PROVISION=1" 	\\
     theiconic/docker-nginx-akeneo
EOF

chmod u+x run.sh
```
 Now you can sit back and run this:
 ```BASH
 run.sh /path/to/akeneo/pim/repo
 ```
That's it. Don't forget to modify your `run.sh` with relevant values.


### Known Issues
In case you get an exception:
```BASH
request.CRITICAL: Uncaught PHP Exception Twig_Error_Runtime: "An exception has been thrown during the rendering of a template ("Error during translations file generation for locale "en_US"")." at /var/www/pim/src/Oro/Bundle/TranslationBundle/Resources/views/requirejs.config.js.twig line 4 {"exception":"[object] (Twig_Error_Runtime(code: 0): An exception has been thrown during the rendering of a template (\"Error during translations file generation for locale \"en_US\"\"). at /var/www/pim/src/Oro/Bundle/TranslationBundle/Resources/views/requirejs.config.js.twig:4, RuntimeException(code: 0): Error during translations file generation for locale \"en_US\" at /var/www/pim/src/Pim/Bundle/EnrichBundle/Twig/TranslationsExtension.php:70)"} []
```

You can attempt to recompile the locale assests:
```
docker exec  <docker-ID> php /var/www/pim/app/console  --env=dev oro:translation:dump en_US
```
