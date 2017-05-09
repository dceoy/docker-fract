docker-fract
============

Dockerfile for [fractus](https://github.com/dceoy/fractus)

Docker image
------------

Pull the image from [Docker Hub](https://hub.docker.com/r/dceoy/fract/)

```sh
$ docker pull dceoy/fract
```

Deployment on DigitalOcean
--------------------------

1.  Set up Tugboat.

    ```sh
    $ gem install --no-document tugboat
    $ tugboat authorize
    # => set `docker-16-04` for "image"
    ```

2.  Set an SSH keys.

    ```sh
    $ tugboat add-key -p /path/to/public_key key_name
    $ vim ~/.tugboat
    # =>  set keys to Tugboat:
    #       - ssh.ssh_key_pat   =>  the path to the secret key
    #       - defaults.ssh_key  =>  the public key ID (shown with `tugboat keys`)
    ```

3.  Create a droplet on DigitalOcean.

    ```sh
    $ tugboat create fract
    ```

4.  Test SSH connection to the droplet.

    ```sh
    $ tugboat ssh fract -c 'echo Hello'
    ```

5.  Deploy fractus on the droplet

    ```sh
    $ git clone https://github.com/dceoy/docker-fract.git
    $ ./docker-fract/deploy_do.sh --droplet fract --fractus-yml /path/to/fractus.yml
    ```

6.  Destroy the droplet

    ```sh
    $ tugboat destroy -y fract
    ```
