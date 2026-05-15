# Housecall Pro API Ruby client

## Available methods

Initialize and create a Lead:

```ruby
lead = Hcp::Lead.new key:, company_id:
lead.create name: 'Alice', phone: '8008008000', email: 'alice@example.com',
  address: { street: '7111 Melrose Ave', city: 'Los Angeles', state: 'CA', zip: '90046' },
  note: 'Very interested in buying', source: 'The Lead Generator'
````

Change the status of a lead in the pipeline:

```ruby
pipeline = Hcp::Lead::Pipeline.new id:, key:, company_id:
pipeline.update status_name: 'Won'
```

