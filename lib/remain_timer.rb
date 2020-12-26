require "remain_timer/version"
require "duration_format"

# rubocop:disable Airbnb/OptArgParameters

class RemainTimer
  attr_accessor :all_count, :estimate_laptime_size

  def initialize(estimate_laptime_size: 20)
    @laptimes = []
    @estimate_laptime_size = estimate_laptime_size
  end

  def start(count = 0, time = now)
    @laptimes << LapTime.new(count, time)
  end

  def progress(count, time = now)
    last_time = @laptimes.last or raise
    @laptimes << LapTime.new(last_time.past_count + count, time)
  end

  def remain_time
    laptimes = @estimate_laptime_size ? @laptimes.last(@estimate_laptime_size) : @laptimes
    first_laptime = laptimes.first or raise
    last_laptime = laptimes.last or raise
    past_count = last_laptime.past_count
    past_duration = last_laptime.time - @laptimes[0].time
    period_past_count = last_laptime.past_count - first_laptime.past_count
    period_past_duration = last_laptime.time - first_laptime.time
    if all = all_count
      remain_count = all - past_count
      if period_past_count > 0
        remain_duration = period_past_duration / period_past_count * remain_count
        all_duration = past_duration + remain_duration
      end
    end

    RemainTime.new(
      all_duration: all_duration,
      past_duration: past_duration,
      remain_duration: remain_duration,
      all_count: all_count,
      past_count: past_count,
      remain_count: remain_count,
    )
  end

  private

  def now
    (@use_current ||= Time.respond_to?(:current)) ? Time.current : Time.now
  end

  LapTime = __any__ = Struct.new(:past_count, :time)

  RemainTime = __any__ =
    Struct.new(
      :all_duration,
      :past_duration,
      :remain_duration,
      :all_count,
      :past_count,
      :remain_count,
      keyword_init: true,
    ) do
      def to_s
        "past: #{dfmt past_duration} / remain: #{dfmt remain_duration} / all: #{
          dfmt all_duration
        } || past: #{past_count} / remain: #{remain_count || "?"} / all: #{all_count || "?"}"
      end

      def puts(prefix: nil, postfix: nil)
        Kernel.puts [prefix, to_s, postfix].compact.join(" ")
      end

      def print(prefix: nil, postfix: nil)
        Kernel.print [prefix, to_s, postfix].compact.join(" ")
      end

      private

      def dfmt(duration)
        duration.nil? ? "?" : DurationFormat.format(duration)
      end
    end
end

# rubocop:enable Airbnb/OptArgParameters
