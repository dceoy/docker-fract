docker-fract
============

Dockerfile for [fract](https://github.com/dceoy/fract)

Docker image
------------

Pull the image from [Docker Hub](https://hub.docker.com/r/dceoy/fract/)

```sh
$ docker pull dceoy/fract
```

Deployment on DigitalOcean
--------------------------

1.  Install [doctl](https://www.digitalocean.com/docs/apis-clis/doctl/).

2.  Set up doctl.

    ```sh
    # Set an access token
    $ doctl auth init

    # Import an SSH key
    $ doctl compute ssh-key import id_rsa --public-key-file /path/to/id_rsa.pub
    $ doctl compute ssh-key list
    ```

3.  Edit the `config.yaml`.

    - Paths to `config.yaml`
      - macOS: `~/Library/Application Support/doctl/config.yaml`
      - Linux: `~/.config/doctl/config.yaml`
    - Keys to fill
      - `droplet.create.image`: docker-20-04
      - `droplet.create.region`: nyc1
      - `droplet.create.size`: s-1vcpu-1gb
      - `droplet.create.ssh-keys`: (fingerprints)
      - `compute.ssh.ssh-key-path`: /path/to/id_rsa

3.  Create a droplet on DigitalOcean.

    ```sh
    $ doctl compute droplet create --wait fract
    ```

4.  Test SSH connection to the droplet.

    ```sh
    $ doctl compute ssh --ssh-command='ls -la' fract
    ```

5.  Deploy fract on the droplet

    ```sh
    $ git clone https://github.com/dceoy/docker-fract.git
    $ ./docker-fract/deploy.sh --droplet fract --fract-yml /path/to/fract.yml
    ```

6.  Destroy the droplet

    ```sh
    $ doctl compute droplet delete -f fract
    ```
