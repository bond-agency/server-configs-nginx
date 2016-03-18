# [Nginx Server Configs](https://github.com/bond-agency/server-configs-nginx)

**Nginx Server Configs** is a collection of configuration snippets that can help
your server improve the web site's performance and security, while also
ensuring that resources are served with the correct content-type and are
accessible, if needed, even cross-domain.


## Documentation

The [documentation](doc/TOC.md) is bundled with
the project, which makes it readily available for offline reading and provides a
useful starting point for any documentation you want to write about your project.


## Contributing to this project

Anyone and everyone is welcome to contribute, but please take a moment to review
the [contributing guidelines](CONTRIBUTING.md).

* [Bug reports](CONTRIBUTING.md#bugs)
* [Feature requests](CONTRIBUTING.md#features)
* [Pull requests](CONTRIBUTING.md#pull-requests)


## Acknowledgements

Nginx Server Configs is only possible thanks to all the awesome
[contributors](https://github.com/bond-agency/server-configs-nginx/graphs/contributors)!


## License

The code is available under the [MIT license](LICENSE.txt).

## Note of BONDs modifications

We have modified the setup to work with our companys nginx setup so if you use this setup make sure you test the configuration with:

```sudo nginx -t```

before reloading or restarting the server with new confs.
