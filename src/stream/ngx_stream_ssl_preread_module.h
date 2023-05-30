
#ifndef _NGX_STREAM_SSL_PREREAD_MODULE_H_INCLUDED_
#define _NGX_STREAM_SSL_PREREAD_MODULE_H_INCLUDED_

#ifndef OPENSSL_NO_ECH
typedef struct {
    ngx_flag_t      enabled;
#ifndef OPENSSL_NO_ECH
    ngx_str_t       echkeydir;
    ngx_ssl_t       *ssl;
#endif
} ngx_stream_ssl_preread_srv_conf_t;


typedef struct {
    size_t          left;
    size_t          size;
    size_t          ext;
    u_char         *pos;
    u_char         *dst;
    u_char          buf[4];
    u_char          version[2];
    ngx_str_t       host;
    ngx_str_t       alpn;
    ngx_log_t      *log;
    ngx_pool_t     *pool;
    ngx_uint_t      state;
#ifndef OPENSSL_NO_ECH
    ngx_uint_t      ech_state;
    u_char          *hrrtok;
    size_t          hrrtoklen;
#endif
} ngx_stream_ssl_preread_ctx_t;

extern ngx_module_t  ngx_stream_ssl_preread_module;

ngx_int_t ngx_stream_do_ech(
    ngx_stream_ssl_preread_srv_conf_t  *sscf,
    ngx_stream_ssl_preread_ctx_t       *ctx,
    ngx_connection_t                   *c,
    u_char                             *p,
    u_char                             **last,
    int                                *dec_ok);

#endif
#endif
