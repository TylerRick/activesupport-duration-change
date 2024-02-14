RSpec.describe ActiveSupport::Duration, '.from_parts' do
  it do
    parts = {minutes: 30.5, seconds: 30.5}
    duration = ActiveSupport::Duration.from_parts(parts)
    expect(duration.parts).to eq({minutes: 31, seconds: 0.5})
    # TODO: don't use if standalone gem
    expect(duration.to_human_s).to eq('31m 0.5s')
  end

  it do
    parts = {minutes: 30.5, seconds: 30.5}
    duration = ActiveSupport::Duration.from_parts(parts, normalize: false)
    expect(duration.parts).to eq(parts)
    # TODO: don't use if standalone gem
    expect(duration.to_human_s).to eq('31m 0.5s')
  end

  it 'is inverse of .parts'
end

RSpec.describe ActiveSupport::Duration, '#change/#change_cascade' do
  it '{hours: 9, minutes: 10, seconds: 40}' do
    # duration = ActiveSupport::Duration.from_parts({hours: 9, minutes: 10, seconds: 40}, normalize: false)
    duration = 9.hours + 10.minutes + 40.seconds
    expect(duration                           .parts).to eq({hours: 9,  minutes: 10, seconds: 40})
    expect(duration.change(        hours: 12 ).parts).to eq({hours: 12, minutes: 10, seconds: 40})
    expect(duration.change_cascade(hours: 12 ).parts).to eq({hours: 12})
    expect(duration.change_cascade(minutes: 5).parts).to eq({hours: 9,  minutes:  5})
  end

  describe '1830.50' do
    let(:value) { 1830.50 }
    let(:duration) { ActiveSupport::Duration.build(value) }
    it { expect(duration.parts).to eq({minutes: 30, seconds: 30.5}) }

    it do
      new = duration.change(minutes: 1)
      expect(new.parts).to eq({minutes: 1, seconds: 30.5})
    end

    it do
      new = duration.change_cascade(minutes: 1)
      expect(new.parts).to eq({minutes: 1})
    end
  end

  it '{hours: 1, minutes: 29, seconds: 60}' do
    duration = ActiveSupport::Duration.from_parts({hours: 1, minutes: 29, seconds: 60}, normalize: false)
    expect(duration                         .parts).to eq({hours: 1, minutes: 29, seconds: 60})
    expect(duration.change(        hours: 1).parts).to eq({hours: 1, minutes: 29, seconds: 60})
    expect(duration.change_cascade(hours: 1).parts).to eq({hours: 1})
  end
end

RSpec.describe ActiveSupport::Duration, '#change_cascade' do
  describe '1830.50' do
    let(:value) { 1830.50 }
    let(:duration) { ActiveSupport::Duration.build(value) }
    it { expect(duration.parts).to eq({minutes: 30, seconds: 30.5}) }

    it do
      durations(value).each do |duration|
      end
    end
  end
end

RSpec.describe ActiveSupport::Duration, '#normalize' do
  it 'fractional unit' do
    parts = { minutes: 1.4, seconds: 25 }
    duration = ActiveSupport::Duration.from_parts(parts, normalize: false)
    expect(duration.          parts).to eq(parts)
    expect(duration.normalize.parts).to eq({ minutes: 1, seconds: 49 })
    expect(duration.normalize.parts).to eq({ minutes: 1, seconds: 0.4 * 60 + 25 * 1 })
  end

  describe 'more than max for unit: 61 seconds' do
    let(:value) { 61 }
    let(:duration) { ActiveSupport::Duration.seconds(value) }
    it { expect(duration.          parts).to eq({             seconds: 61}) }
    it { expect(duration.normalize.parts).to eq({minutes:  1, seconds:  1}) }
  end

  describe '1830.50' do
    let(:value) { 1830.50 }
    let(:duration) { ActiveSupport::Duration.seconds(value) }
    it { expect(duration.          parts).to eq({             seconds: 1830.5}) }
    it { expect(duration.normalize.parts).to eq({minutes: 30, seconds: 30.5}) }
  end
end

RSpec.describe ActiveSupport::Duration, '#smaller_parts' do
  it '{hours: 1, minutes: 29, seconds: 60}' do
    duration = ActiveSupport::Duration.from_parts( { hours: 1, minutes: 29, seconds: 60 }, normalize: false)
    expect(duration.normalize.parts        ).to eq({ hours: 1, minutes: 30 })
    expect(duration.smaller_parts(:hours)  ).to eq({           minutes: 29, seconds: 60 })
    expect(duration.smaller_parts(:minutes)).to eq({                        seconds: 60 })
    expect(duration.smaller_parts(:seconds)).to eq({                                    })
  end
end

RSpec.describe ActiveSupport::Duration, '#truncate/#round' do
  it do
    duration = ActiveSupport::Duration.seconds(2.5)
    expect(duration.truncate(:seconds).parts).to eq({seconds: 2})
    expect(duration.   round(:seconds).parts).to eq({seconds: 3})
  end

  it do
    duration = ActiveSupport::Duration.from_parts({ minutes: 1, seconds: 29 }, normalize: false)
    expect(duration.truncate(:minutes).parts).to eq({minutes: 1})
    expect(duration.   round(:minutes).parts).to eq({minutes: 1})
  end

  it do
    duration = ActiveSupport::Duration.from_parts({ hours: 1, minutes: 29 }, normalize: false)
    expect(duration.truncate(:hours).parts).to eq({hours: 1})
    expect(duration.   round(:hours).parts).to eq({hours: 1})
  end

  it do
    duration = ActiveSupport::Duration.from_parts({ hours: 1, minutes: 89 }, normalize: false)
    expect(duration.          truncate(:hours).parts).to eq({hours: 1})
    expect(duration.normalize                 .parts).to eq({hours: 2, minutes: 29})
    expect(duration.normalize.truncate(:hours).parts).to eq({hours: 2})
    expect(duration.   round(:hours                 ).parts).to eq({hours: 2})
    expect(duration.   round(:hours                 ).parts).to eq({hours: 2})
  end

  it do
    duration = ActiveSupport::Duration.from_parts({ hours: 1, minutes: 90 }, normalize: false)
    expect(duration.          truncate(:hours).parts).to eq({hours: 1})
    expect(duration.normalize                 .parts).to eq({hours: 2, minutes: 30})
    expect(duration.normalize.truncate(:hours).parts).to eq({hours: 2})
    expect(duration.             round(:hours).parts).to eq({hours: 3})
  end

  it do
    duration = ActiveSupport::Duration.seconds(30)
    expect(duration.truncate(:minutes).parts).to eq({ })
    expect(duration.truncate(:minutes).value).to eq(0)
    expect(duration.   round(:minutes).parts).to eq({minutes: 1})
  end

  it do
    duration = ActiveSupport::Duration.seconds(89) # 1m + 29s
    expect(duration.          truncate(:minutes).parts).to eq({})
    expect(duration.normalize                   .parts).to eq({minutes: 1, seconds: 29})
    expect(duration.normalize.truncate(:minutes).parts).to eq({minutes: 1})
    expect(duration.             round(:minutes).parts).to eq({minutes: 1})
  end

  it do
    duration = ActiveSupport::Duration.seconds(90) # 1m + 30s
    expect(duration.normalize.truncate(:minutes).parts).to eq({minutes: 1})
    expect(duration.             round(:minutes).parts).to eq({minutes: 2})
  end

  describe 'default precision is smallest_unit' do
    it do
      duration = ActiveSupport::Duration.from_parts({ hours: 1, minutes: 29.5 }, normalize: false)
      expect(duration.truncate.parts).to eq({hours: 1, minutes: 29})
      expect(duration.   round.parts).to eq({hours: 1, minutes: 30})
    end

    it do
      expect(2.5.seconds.round)             .to eq 3.seconds
      expect(2.5.seconds.round(half: :down)).to eq 2.seconds
    end
  end

  it do
    duration = ActiveSupport::Duration.from_parts({ minutes: 1, seconds: 30 }, normalize: false)
    expect(duration.truncate(:minutes).parts).to eq({minutes: 1})
    expect(duration.   round(:minutes).parts).to eq({minutes: 2})
  end

  it do
    duration = ActiveSupport::Duration.from_parts({ minutes: 1.4, seconds: 25 }, normalize: false)
    expect(duration.normalize.parts).to eq({ minutes: 1, seconds: 49 })
    expect(duration.truncate(:minutes).parts).to eq({minutes: 1})
    expect(duration.   round(:minutes).parts).to eq({minutes: 2})
  end

  it '{hours: 1, minutes: 29, seconds: 60}' do
    duration = ActiveSupport::Duration.from_parts({hours: 1, minutes: 29, seconds: 60}, normalize: false)
    expect(duration.normalize       .parts).to eq({hours: 1, minutes: 30})
    expect(duration.truncate(:hours).parts).to eq({hours: 1})
    expect(duration.normalize.round(:hours).parts).to eq({hours: 2})
    expect(duration.          round(:hours).parts).to eq({hours: 2})
  end

  it 'larger parts are untouched' do
    duration = ActiveSupport::Duration.from_parts({days: 1, hours: 1, minutes: 30}, normalize: false)
    expect(duration.truncate(:hours                  ).parts).to eq({days: 1, hours: 1})
    expect(duration.   round(:hours                  ).parts).to eq({days: 1, hours: 2})
  end

  describe '1.4 minutes + 25 seconds' do
    let(:parts) { { minutes: 1.4, seconds: 25 } }
    let(:duration) { ActiveSupport::Duration.from_parts(parts, normalize: false) }

    it do
      expect(duration.truncate(:minutes).parts).to eq({minutes: 1})
      expect(duration.   round(:minutes).parts).to eq({minutes: 2})
    end
  end

  describe '1 minute + 29.9 seconds' do
    let(:parts) { {minutes: 1, seconds: 29.9} }
    let(:duration) { ActiveSupport::Duration.from_parts(parts, normalize: false) }

    it do
      expect(duration.truncate(:minutes).parts).to eq({minutes: 1})
      expect(duration.   round(:minutes).parts).to eq({minutes: 1})
    end
  end

  describe '1830.50 seconds' do
    let(:value) { 1830.50 }
    let(:duration) { ActiveSupport::Duration.build(value) }
    it { expect(duration.parts).to eq({minutes: 30, seconds: 30.5}) }

    it do
      expect(duration.truncate(:seconds).parts).to eq({minutes: 30, seconds: 30})
      expect(duration.   round(:seconds).parts).to eq({minutes: 30, seconds: 31})
    end

    it do
      duration = seconds(value)
      expect(duration                                   .parts).to eq({seconds: 1830.5})
      expect(duration.normalize                         .parts).to eq({minutes: 30, seconds: 30.5})
      expect(duration.truncate(:hours                  ).parts).to eq({}) # hours: 0
      expect(duration.   round(:hours                  ).parts).to eq({hours: 1})

      expect(duration.          truncate(:minutes).parts).to eq({}) # minutes: 0
      expect(duration.normalize.truncate(:minutes).parts).to eq({minutes: 30})
      expect(duration.             round(:minutes).parts).to eq({minutes: 31})

      expect(duration.normalize.truncate(:seconds).parts).to eq({minutes: 30, seconds: 30})
      expect(duration.             round(:seconds).parts).to eq({             seconds: 1831})
      expect(duration.normalize.   round(:seconds).parts).to eq({minutes: 30, seconds: 31})
    end

    it do
      expect(duration.truncate(:minutes).parts).to eq({minutes: 30})
      expect(duration.   round(:minutes).parts).to eq({minutes: 31})

      duration = seconds(value).normalize
      expect(duration.truncate(:minutes).parts).to eq({minutes: 30})
      expect(duration.   round(:minutes).parts).to eq({minutes: 31})
    end

#    it do
#      durations(value).each do |duration|
#        expect(duration.truncate(:hours).parts).to eq({hours: 1})
#        expect(duration.   round(:hours).parts).to eq({})
#        expect(duration.   round(:hours).value).to eq(0)
#      end
#    end
  end

#  it do
#    durations(3510.50).each do |duration|
#      expect(duration.truncate(:hours).parts).to eq({})
#      expect(duration.   round(:hours).parts).to eq({hours: 59})
#    end
#  end

end
