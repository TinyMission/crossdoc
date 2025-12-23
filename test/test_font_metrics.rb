# frozen_string_literal: true

require 'crossdoc'
require 'minitest/autorun'

class TestFontMetrics < Minitest::Spec
  LOREM_IPSUM = <<~EOF.split.join(' ')
    Ut magnam nobis tempore qui natus. Et eos nihil sequi reprehenderit. Dolor
    incidunt veniam sunt ut labore porro cumque. Vel quam corrupti repellat
    dolore recusandae. Quibusdam aut est ducimus quia at sit quod. Ad provident
    molestiae ex recusandae aliquid ut corporis numquam. Blanditiis qui est odio
    sit debitis nihil natus. Quaerat et aspernatur dolore numquam. Qui sit earum
    ducimus voluptatum et. Consequatur incidunt neque itaque eaque debitis aut.
    Ipsa expedita sapiente sit reiciendis illum sunt repellendus ut. Ratione id
    reprehenderit placeat quibusdam. Nulla et mollitia non enim. Sit sed quae
    quia consequuntur. Inventore illum aspernatur odit dignissimos recusandae
    voluptatem impedit. In beatae est molestiae et. Vitae officiis eos velit
    nesciunt adipisci sint. Blanditiis aut dicta corrupti veritatis facere
    mollitia. Voluptatem labore veritatis quis. Voluptas dolorum totam odio
    aliquam. Non et nostrum et delectus. Id voluptatum cumque quod voluptas sunt
    in ut. Officiis non est qui nemo eos rerum velit. Est suscipit sint vitae non
    omnis quia. Qui deleniti earum id eos aut. Vel eum accusantium praesentium
    ipsam est.
  EOF

  it 'return the correct number of lines for some Lorem Ipsum' do
    # NOTE: 12 is the pixel size, not the point size.
    num_lines = CrossDoc::FontMetrics.num_lines(LOREM_IPSUM, 1046, 12, 'Helvetica')
    _(num_lines).must_equal 6
  end
end
